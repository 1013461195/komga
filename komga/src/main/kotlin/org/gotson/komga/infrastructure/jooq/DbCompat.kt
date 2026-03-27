package org.gotson.komga.infrastructure.jooq

import org.gotson.komga.infrastructure.datasource.SqliteUdfDataSource
import org.jooq.Field
import org.jooq.impl.DSL

/**
 * Database compatibility layer.
 * Abstracts SQLite-specific functions so the codebase can support multiple database backends.
 */
object DbCompat {
  var dialect: DbType = DbType.SQLITE

  fun caseInsensitive(field: Field<String>): Field<String> =
    when (dialect) {
      DbType.SQLITE -> field.collate("NOCASE")
      DbType.POSTGRESQL -> field.lower()
    }

  fun unicodeCollation(field: Field<String>): Field<String> =
    when (dialect) {
      DbType.SQLITE -> field.collate(SqliteUdfDataSource.COLLATION_UNICODE_3)
      DbType.POSTGRESQL -> field.collate("und-x-icu")
    }

  fun stripAccents(field: Field<String>): Field<String> =
    when (dialect) {
      DbType.SQLITE -> DSL.function(SqliteUdfDataSource.UDF_STRIP_ACCENTS, String::class.java, field)
      DbType.POSTGRESQL -> DSL.function("unaccent", String::class.java, field)
    }

  enum class DbType { SQLITE, POSTGRESQL }
}
