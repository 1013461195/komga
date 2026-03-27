package org.gotson.komga.infrastructure.jooq

import jakarta.annotation.PostConstruct
import org.gotson.komga.infrastructure.configuration.KomgaProperties
import org.springframework.context.annotation.Configuration
import org.springframework.core.Ordered
import org.springframework.core.annotation.Order

@Configuration
@Order(Ordered.HIGHEST_PRECEDENCE)
class DbCompatConfiguration(
  private val komgaProperties: KomgaProperties,
) {
  @PostConstruct
  fun init() {
    DbCompat.dialect =
      if (komgaProperties.database.type == "postgresql")
        DbCompat.DbType.POSTGRESQL
      else
        DbCompat.DbType.SQLITE
  }
}
