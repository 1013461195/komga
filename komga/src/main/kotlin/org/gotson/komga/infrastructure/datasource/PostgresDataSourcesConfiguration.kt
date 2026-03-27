package org.gotson.komga.infrastructure.datasource

import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.gotson.komga.infrastructure.configuration.KomgaProperties
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.context.annotation.Primary
import javax.sql.DataSource

@Configuration
@ConditionalOnProperty(name = ["komga.database.type"], havingValue = "postgresql")
class PostgresDataSourcesConfiguration(
  private val komgaProperties: KomgaProperties,
) {
  private fun buildDataSource(poolName: String): HikariDataSource {
    val poolSize = komgaProperties.database.poolSize
      ?: Runtime.getRuntime().availableProcessors().coerceAtMost(komgaProperties.database.maxPoolSize)

    return HikariDataSource(
      HikariConfig().apply {
        this.jdbcUrl = komgaProperties.database.file
        this.username = komgaProperties.database.username
        this.password = komgaProperties.database.password
        this.poolName = poolName
        this.maximumPoolSize = poolSize
      },
    )
  }

  @Bean("sqliteDataSourceRW")
  @Primary
  fun mainDataSourceRW(): DataSource = buildDataSource("PgMainPool")

  @Bean("sqliteDataSourceRO")
  fun mainDataSourceRO(): DataSource = mainDataSourceRW()

  @Bean("tasksDataSourceRW")
  fun tasksDataSourceRW(): DataSource = mainDataSourceRW()

  @Bean("tasksDataSourceRO")
  fun tasksDataSourceRO(): DataSource = mainDataSourceRW()
}
