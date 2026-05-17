package org.gotson.komga.infrastructure.datasource

import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainer

/**
 * Base class for tests that require a PostgreSQL database via Testcontainers.
 *
 * Usage: Extend this class and add @SpringBootTest with the desired test configuration.
 * The PostgreSQL container will be started automatically and its connection properties
 * will be injected into the Spring context.
 */
@Testcontainer
@SpringBootTest
@ActiveProfiles("test", "test-pg")
abstract class PostgresTestContainer {
  companion object {
    @Container
    @JvmStatic
    val postgres: PostgreSQLContainer<*> =
      PostgreSQLContainer("postgres:16-alpine")
        .withDatabaseName("komga_test")
        .withUsername("komga")
        .withPassword("komga")
        .withCommand("postgres", "-c", "shared_preload_libraries=pg_stat_statements")

    @DynamicPropertySource
    @JvmStatic
    fun registerProperties(registry: DynamicPropertyRegistry) {
      registry.add("komga.database.file") { postgres.jdbcUrl }
      registry.add("komga.database.username") { postgres.username }
      registry.add("komga.database.password") { postgres.password }
      registry.add("komga.tasks-db.file") { postgres.jdbcUrl }
      registry.add("komga.tasks-db.username") { postgres.username }
      registry.add("komga.tasks-db.password") { postgres.password }
    }
  }
}
