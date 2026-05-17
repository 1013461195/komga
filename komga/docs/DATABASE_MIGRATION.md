# Komga Database Migration Guide

This document describes how to maintain database migrations for both SQLite and PostgreSQL backends.

## Overview

Komga supports two database backends:
- **SQLite** (default) - File-based database, suitable for single-user deployments
- **PostgreSQL** - Server-based database, suitable for multi-user or enterprise deployments

Each backend has its own set of Flyway migration files located at:
- SQLite: `komga/src/flyway/resources/db/migration/sqlite/`
- PostgreSQL: `komga/src/flyway/resources/db/migration/postgresql/`

Tasks migrations:
- SQLite: `komga/src/flyway/resources/tasks/migration/sqlite/`
- PostgreSQL: `komga/src/flyway/resources/tasks/migration/postgresql/`

## Adding New Migrations

When you need to modify the database schema, you must create migration files for **both** backends.

### Step 1: Create SQLite Migration

Create a new SQL file in the SQLite migration directory:

```
komga/src/flyway/resources/db/migration/sqlite/V{VERSION}__{description}.sql
```

Example:
```sql
-- V20250801120000__add_new_column.sql
ALTER TABLE BOOK ADD COLUMN NEW_COLUMN varchar(255) DEFAULT NULL;
```

### Step 2: Create PostgreSQL Migration

Create a corresponding SQL file in the PostgreSQL migration directory with the **same version number**:

```
komga/src/flyway/resources/db/migration/postgresql/V{VERSION}__{description}.sql
```

Example:
```sql
-- V20250801120000__add_new_column.sql
ALTER TABLE BOOK ADD COLUMN NEW_COLUMN text DEFAULT NULL;
```

### Step 3: Update jOOQ Generated Code

After adding migrations, regenerate the jOOQ code:

```bash
./gradlew generateJooq generateTasksJooq
```

This will update the generated Java/Kotlin classes to reflect the new schema.

## SQL Syntax Differences

### Data Types

| SQLite | PostgreSQL | Notes |
|--------|------------|-------|
| `varchar(N)` | `text` | PostgreSQL has no practical length limit for `text` |
| `integer` | `integer` | Same |
| `int8` | `bigint` | Same |
| `real` | `real` | Same |
| `blob` | `bytea` | Binary data |
| `boolean` | `boolean` | SQLite uses 0/1, PostgreSQL uses true/false |
| `datetime` | `timestamp` | Timestamp type |

### Functions and Expressions

| SQLite | PostgreSQL | Notes |
|--------|------------|-------|
| `datetime('now')` | `CURRENT_TIMESTAMP` or `now()` | |
| `hex(randomblob(32))` | `encode(gen_random_bytes(32), 'hex')` | Random hex string |
| `CAST(x AS varchar)` | `CAST(x AS text)` | |
| `PRAGMA table_info(...)` | `information_schema.columns` | Schema introspection |
| `IFNULL(x, y)` | `COALESCE(x, y)` | Null handling |
| `GROUP_CONCAT(x)` | `STRING_AGG(x, ',')` | String aggregation |
| `LIKE` (case-insensitive by default) | `ILIKE` or `LOWER() LIKE LOWER()` | Case sensitivity |
| `AUTOINCREMENT` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` | Auto-increment |

### Quoting Identifiers

- SQLite: `[TABLE_NAME]` or `"TABLE_NAME"`
- PostgreSQL: `"TABLE_NAME"` (double quotes only)

PostgreSQL has more reserved words. Always quote table/column names that might be reserved:
- `"USER"` (reserved in PostgreSQL)
- `"ORDER"`, `"GROUP"`, `"TABLE"`, etc.

### Boolean Handling

SQLite stores booleans as integers (0/1). PostgreSQL uses native boolean type.

When inserting data:
```sql
-- SQLite
INSERT INTO table (flag) VALUES (1);

-- PostgreSQL
INSERT INTO table (flag) VALUES (true);
```

### Temporary Tables

Both databases support temporary tables with similar syntax:
```sql
CREATE TEMPORARY TABLE temp_name (column_name text NOT NULL);
```

The `TempTable` class in Komga handles this automatically based on the configured dialect.

## Testing Migrations

### SQLite Tests

SQLite tests run automatically in CI:
```bash
./gradlew test
```

### PostgreSQL Tests

PostgreSQL tests use Testcontainers and require Docker:
```bash
./gradlew test --tests "*Postgres*"
```

## Data Migration

To migrate data from SQLite to PostgreSQL, use the provided migration script:

```bash
python3 komga/scripts/migrate_sqlite_to_postgresql.py \
    --sqlite-db /path/to/database.sqlite \
    --pg-url postgresql://user:password@host:port/dbname \
    --tasks-sqlite /path/to/tasks.sqlite
```

See the script's `--help` for more options.

## Best Practices

1. **Always test both backends** before merging schema changes
2. **Use the compatibility layer** (`DbCompat`) for dialect-specific operations
3. **Keep migration versions in sync** between SQLite and PostgreSQL
4. **Use jOOQ's DSL** instead of raw SQL when possible for cross-database compatibility
5. **Quote identifiers** that might be reserved words in PostgreSQL
6. **Use `text` instead of `varchar(N)`** in PostgreSQL migrations unless length constraints are required

## Troubleshooting

### PostgreSQL `unaccent` Extension

The PostgreSQL backend requires the `unaccent` extension. If you see errors like:
```
ERROR: function unaccent(text) does not exist
```

Install the extension:
```sql
CREATE EXTENSION IF NOT EXISTS unaccent;
```

This is done automatically by the V1 migration, but may need to be done manually if the extension was removed.

### jOOQ Type Mapping Issues

If you encounter type mapping issues with jOOQ, check:
1. The generated code is up-to-date: `./gradlew generateJooq`
2. The column types in the PostgreSQL schema match the SQLite schema
3. The `DbCompat` layer handles the specific operation you need

### Connection Pool Issues

PostgreSQL uses a single connection pool for all datasources (unlike SQLite which separates read/write). If you experience connection pool exhaustion, increase `komga.database.max-pool-size`.
