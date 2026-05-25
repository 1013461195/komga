package org.gotson.komga.infrastructure.datasource

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import javax.sql.DataSource

class PostgresDataSourcesConfigurationTest : PostgresTestContainer() {
  @Autowired
  private lateinit var dataSourceRW: DataSource

  @Autowired
  @Qualifier("mainDataSourceRO")
  private lateinit var dataSourceRO: DataSource

  @Autowired
  @Qualifier("tasksDataSourceRW")
  private lateinit var tasksDataSourceRW: DataSource

  @Autowired
  @Qualifier("tasksDataSourceRO")
  private lateinit var tasksDataSourceRO: DataSource

  @Test
  fun `given postgresql when autowiring beans then all beans point to the same datasource`() {
    // PostgreSQL uses a single pool for all datasources
    assertThat(dataSourceRW).isSameAs(dataSourceRO)
    assertThat(dataSourceRW).isSameAs(tasksDataSourceRW)
    assertThat(dataSourceRW).isSameAs(tasksDataSourceRO)
  }

  @Test
  fun `given postgresql when connecting then connection is valid`() {
    dataSourceRW.connection.use { conn ->
      assertThat(conn.isValid(5)).isTrue()
      // Verify unaccent extension is available
      conn.createStatement().use { stmt ->
        stmt.executeQuery("SELECT unaccent('test')").use { rs ->
          assertThat(rs.next()).isTrue()
          assertThat(rs.getString(1)).isEqualTo("test")
        }
      }
    }
  }
}
