#!/usr/bin/env python3
"""
Komga Data Migration Tool: SQLite to PostgreSQL

This script migrates data from a Komga SQLite database to a PostgreSQL database.
It handles the differences in data types and SQL syntax between the two databases.

Usage:
    python3 migrate_sqlite_to_postgresql.py \
        --sqlite-db /path/to/database.sqlite \
        --pg-url postgresql://user:password@host:port/dbname \
        [--tasks-sqlite /path/to/tasks.sqlite] \
        [--batch-size 1000] \
        [--dry-run]

Requirements:
    pip install psycopg2-binary

Note:
    - The PostgreSQL database must have the Komga schema already created (via Flyway)
    - The SQLite database should be from a compatible Komga version
    - Back up both databases before migration
"""

import argparse
import sqlite3
import sys
import logging
from datetime import datetime
from typing import Any, Optional

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print("Error: psycopg2 is required. Install with: pip install psycopg2-binary")
    sys.exit(1)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# Table migration order (respects foreign key dependencies)
TABLE_ORDER = [
    "LIBRARY",
    "USER",
    "USER_ROLE",
    "USER_LIBRARY_SHARING",
    "USER_SHARING",
    "USER_API_KEY",
    "SERIES",
    "SERIES_METADATA",
    "SERIES_METADATA_SHARING",
    "BOOK",
    "BOOK_METADATA",
    "MEDIA",
    "MEDIA_PAGE",
    "THUMBNAIL_BOOK",
    "THUMBNAIL_SERIES",
    "THUMBNAIL_COLLECTION",
    "READ_PROGRESS",
    "COLLECTION",
    "COLLECTION_SERIES",
    "READLIST",
    "READLIST_BOOK",
    "SIDECAR",
    "ANALYZE_DIMENSION_TASK",
    "FILE_HASH",
    "BOOK_PAGE_HASH",
    "A2A",
    "A2A_BOOK",
    "A2A_SERIES",
    "SETTINGS",
    "USER_DEVICE",
    "OPDS_FEED",
    "OPDS_FEED_ENTRY",
    "KOREADER_SYNC",
]

TASKS_TABLE_ORDER = [
    "TASK",
]


def convert_value(value: Any, col_type: str, col_name: str) -> Any:
    """Convert SQLite value to PostgreSQL compatible value."""
    if value is None:
        return None

    # Boolean conversion: SQLite uses 0/1, PostgreSQL uses true/false
    if col_type == "boolean":
        return bool(value)

    # Timestamp conversion: SQLite stores as string, PostgreSQL expects datetime
    if col_type == "timestamp":
        if isinstance(value, str):
            # Try common formats
            for fmt in [
                "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%dT%H:%M:%S",
                "%Y-%m-%d %H:%M:%S.%f",
                "%Y-%m-%dT%H:%M:%S.%f",
                "%Y-%m-%d",
            ]:
                try:
                    return datetime.strptime(value, fmt)
                except ValueError:
                    continue
            # If no format matches, return as-is (PostgreSQL might handle it)
            return value
        return value

    # BLOB to bytea: SQLite stores as bytes, PostgreSQL expects bytea
    if col_type == "bytea":
        if isinstance(value, str):
            # SQLite might store hex string
            return bytes.fromhex(value) if value.startswith("\\x") else value.encode()
        return value

    return value


def get_table_columns(cursor: sqlite3.Cursor, table_name: str) -> list[str]:
    """Get column names for a table."""
    cursor.execute(f"PRAGMA table_info({table_name})")
    return [row[1] for row in cursor.fetchall()]


def get_pg_column_types(pg_cursor, table_name: str) -> dict[str, str]:
    """Get column type mapping from PostgreSQL."""
    pg_cursor.execute(
        """
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_name = %s
        ORDER BY ordinal_position
        """,
        (table_name.lower(),),
    )
    return {row[0].upper(): row[1] for row in pg_cursor.fetchall()}


def migrate_table(
    sqlite_conn: sqlite3.Connection,
    pg_conn,
    table_name: str,
    batch_size: int,
    dry_run: bool = False,
) -> int:
    """Migrate a single table from SQLite to PostgreSQL."""
    sqlite_cursor = sqlite_conn.cursor()
    pg_cursor = pg_conn.cursor()

    # Get columns
    columns = get_table_columns(sqlite_cursor, table_name)
    if not columns:
        logger.warning(f"Table {table_name} not found in SQLite, skipping")
        return 0

    # Get PostgreSQL column types
    pg_col_types = get_pg_column_types(pg_cursor, table_name)
    if not pg_col_types:
        logger.warning(f"Table {table_name} not found in PostgreSQL, skipping")
        return 0

    # Read all data from SQLite
    col_list = ", ".join(f'"{c}"' for c in columns)
    sqlite_cursor.execute(f"SELECT {col_list} FROM [{table_name}]")
    rows = sqlite_cursor.fetchall()

    if not rows:
        logger.info(f"Table {table_name}: empty, skipping")
        return 0

    if dry_run:
        logger.info(f"Table {table_name}: would migrate {len(rows)} rows")
        return len(rows)

    # Prepare insert statement
    placeholders = ", ".join(["%s"] * len(columns))
    col_names = ", ".join(f'"{c}"' for c in columns)
    insert_sql = f'INSERT INTO "{table_name}" ({col_names}) VALUES ({placeholders})'

    # Convert and insert in batches
    converted_rows = []
    for row in rows:
        converted = []
        for i, (value, col_name) in enumerate(zip(row, columns)):
            col_type = pg_col_types.get(col_name, "text")
            converted.append(convert_value(value, col_type, col_name))
        converted_rows.append(tuple(converted))

    # Insert in batches
    total_inserted = 0
    for i in range(0, len(converted_rows), batch_size):
        batch = converted_rows[i : i + batch_size]
        execute_values(
            pg_cursor,
            f'INSERT INTO "{table_name}" ({col_names}) VALUES %s',
            batch,
            template=f"({placeholders})",
        )
        total_inserted += len(batch)
        logger.debug(f"  Inserted batch {i // batch_size + 1}: {len(batch)} rows")

    pg_conn.commit()
    logger.info(f"Table {table_name}: migrated {total_inserted} rows")
    return total_inserted


def main():
    parser = argparse.ArgumentParser(
        description="Migrate Komga data from SQLite to PostgreSQL"
    )
    parser.add_argument(
        "--sqlite-db",
        required=True,
        help="Path to the SQLite database file",
    )
    parser.add_argument(
        "--pg-url",
        required=True,
        help="PostgreSQL connection URL (postgresql://user:password@host:port/dbname)",
    )
    parser.add_argument(
        "--tasks-sqlite",
        help="Path to the tasks SQLite database file (optional)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1000,
        help="Number of rows to insert per batch (default: 1000)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be migrated without making changes",
    )
    parser.add_argument(
        "--skip-tables",
        nargs="*",
        default=[],
        help="Tables to skip during migration",
    )

    args = parser.parse_args()

    # Connect to databases
    logger.info(f"Connecting to SQLite: {args.sqlite_db}")
    sqlite_conn = sqlite3.connect(args.sqlite_db)

    logger.info(f"Connecting to PostgreSQL: {args.pg_url.split('@')[1] if '@' in args.pg_url else args.pg_url}")
    pg_conn = psycopg2.connect(args.pg_url)

    try:
        total_rows = 0

        # Migrate main database
        logger.info("=== Migrating main database ===")
        for table in TABLE_ORDER:
            if table in args.skip_tables:
                logger.info(f"Skipping table {table}")
                continue
            total_rows += migrate_table(
                sqlite_conn, pg_conn, table, args.batch_size, args.dry_run
            )

        # Migrate tasks database if provided
        if args.tasks_sqlite:
            logger.info("=== Migrating tasks database ===")
            tasks_conn = sqlite3.connect(args.tasks_sqlite)
            for table in TASKS_TABLE_ORDER:
                if table in args.skip_tables:
                    logger.info(f"Skipping table {table}")
                    continue
                total_rows += migrate_table(
                    tasks_conn, pg_conn, table, args.batch_size, args.dry_run
                )
            tasks_conn.close()

        if args.dry_run:
            logger.info(f"=== DRY RUN: Would migrate {total_rows} total rows ===")
        else:
            logger.info(f"=== Migration complete: {total_rows} total rows migrated ===")

    except Exception as e:
        logger.error(f"Migration failed: {e}")
        pg_conn.rollback()
        raise
    finally:
        sqlite_conn.close()
        pg_conn.close()


if __name__ == "__main__":
    main()
