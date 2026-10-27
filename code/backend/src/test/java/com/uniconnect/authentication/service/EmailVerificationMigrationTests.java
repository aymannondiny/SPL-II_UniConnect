package com.uniconnect.authentication.service;

import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import static org.assertj.core.api.Assertions.assertThat;

class EmailVerificationMigrationTests {
    @Test
    void forwardMigrationInvalidatesLegacyLinksAndPreservesAccountStates() throws Exception {
        String url = "jdbc:h2:mem:verification_upgrade_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (var connection = DriverManager.getConnection(url, "sa", "")) {
            var source = new SingleConnectionDataSource(connection, true);

            Flyway.configure().dataSource(source).locations("classpath:db/migration")
                    .target("26").load().migrate();
            connection.createStatement().executeUpdate("""
                    insert into users (full_name,email,password_hash,platform_role,account_status,created_at,updated_at)
                    values ('Pending','pending@iut-dhaka.edu','hash','STUDENT','PENDING_VERIFICATION',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
                           ('Active','active@iut-dhaka.edu','hash','ALUMNI','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                    """);
            connection.createStatement().executeUpdate("""
                    insert into email_verification_tokens (user_id,token_hash,created_at,expires_at)
                    select user_id, repeat('a',64), CURRENT_TIMESTAMP, DATEADD('HOUR',24,CURRENT_TIMESTAMP)
                    from users where email='pending@iut-dhaka.edu'
                    """);

            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();
            ResultSet legacy = connection.createStatement().executeQuery(
                    "select code_salt,failed_attempts,revoked_at from email_verification_tokens");
            assertThat(legacy.next()).isTrue();
            assertThat(legacy.getString("code_salt")).isEqualTo("legacy-link-invalidated");
            assertThat(legacy.getInt("failed_attempts")).isZero();
            assertThat(legacy.getTimestamp("revoked_at")).isNotNull();

            connection.createStatement().executeUpdate("""
                    insert into email_verification_tokens
                        (user_id,code_digest,code_salt,failed_attempts,created_at,expires_at)
                    select user_id, repeat('b',64), repeat('s',43), 0,
                           CURRENT_TIMESTAMP, DATEADD('MINUTE',10,CURRENT_TIMESTAMP)
                    from users
                    """);

            ResultSet users = connection.createStatement().executeQuery(
                    "select email,account_status from users order by email");
            assertThat(users.next()).isTrue();
            assertThat(users.getString("email")).isEqualTo("active@iut-dhaka.edu");
            assertThat(users.getString("account_status")).isEqualTo("ACTIVE");
            assertThat(users.next()).isTrue();
            assertThat(users.getString("email")).isEqualTo("pending@iut-dhaka.edu");
            assertThat(users.getString("account_status")).isEqualTo("PENDING_VERIFICATION");
        }
    }
}
