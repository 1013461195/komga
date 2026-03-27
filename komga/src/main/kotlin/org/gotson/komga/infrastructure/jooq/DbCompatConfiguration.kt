package org.gotson.komga.infrastructure.jooq

import jakarta.annotation.PostConstruct
import org.gotson.komga.infrastructure.configuration.KomgaProperties
import org.springframework.context.annotation.Configuration

@Configuration
class DbCompatConfiguration(
  private val komgaProperties: KomgaProperties,
) {
  @PostConstruct
  fun init() {
    DbCompat.dialect =
      if (komgaProperties.database.file.startsWith("jdbc:postgresql"))
        DbCompat.DbType.POSTGRESQL
      else
        DbCompat.DbType.SQLITE
  }
}
