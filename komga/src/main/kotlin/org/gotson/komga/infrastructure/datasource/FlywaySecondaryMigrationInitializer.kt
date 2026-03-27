package org.gotson.komga.infrastructure.datasource

import org.flywaydb.core.Flyway
import org.gotson.komga.infrastructure.jooq.DbCompat
import org.springframework.beans.factory.InitializingBean
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.stereotype.Component
import javax.sql.DataSource

@Component
class FlywaySecondaryMigrationInitializer(
  @Qualifier("tasksDataSourceRW")
  private val tasksDataSource: DataSource,
) : InitializingBean {
  // by default Spring Boot will perform migration only on the @Primary datasource
  override fun afterPropertiesSet() {
    val location =
      when (DbCompat.dialect) {
        DbCompat.DbType.SQLITE -> "classpath:tasks/migration/sqlite"
        DbCompat.DbType.POSTGRESQL -> "classpath:tasks/migration/postgresql"
      }
    Flyway
      .configure()
      .locations(location)
      .dataSource(tasksDataSource)
      .load()
      .apply {
        migrate()
      }
  }
}
