package com.uniconnect.authentication.service;

import java.sql.DriverManager;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import static org.assertj.core.api.Assertions.assertThat;

class PasswordResetMigrationTests {
    @Test
    void upgradeRevokesOldLinksAndPreservesPasswordsAndStatuses() throws Exception {
        String url = "jdbc:h2:mem:recovery_upgrade_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (var connection = DriverManager.getConnection(url, "sa", "")) {
            var source = new SingleConnectionDataSource(connection, true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration")
                    .target("27").load().migrate();
            try (var sql = connection.createStatement()) {
                sql.executeUpdate("""
                        insert into users (full_name,email,password_hash,platform_role,account_status,created_at,updated_at)
                        values ('Member','member@iut-dhaka.edu','original-hash','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                        """);
                sql.executeUpdate("""
                        insert into password_reset_tokens (user_id,token_hash,created_at,expires_at)
                        select user_id, repeat('a',64), CURRENT_TIMESTAMP, DATEADD('HOUR',1,CURRENT_TIMESTAMP) from users
                        """);
            }
            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();
            try (var sql = connection.createStatement();
                    var records = sql.executeQuery("select code_salt,failed_attempts,revoked_at from password_reset_tokens")) {
                assertThat(records.next()).isTrue();
                assertThat(records.getString("code_salt")).isNull();
                assertThat(records.getInt("failed_attempts")).isZero();
                assertThat(records.getTimestamp("revoked_at")).isNotNull();
            }
            try (var sql = connection.createStatement();
                    var accounts = sql.executeQuery("select password_hash,account_status from users")) {
                assertThat(accounts.next()).isTrue();
                assertThat(accounts.getString("password_hash")).isEqualTo("original-hash");
                assertThat(accounts.getString("account_status")).isEqualTo("ACTIVE");
            }
        }
    }
}
