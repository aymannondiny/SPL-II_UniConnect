package com.uniconnect.authentication.service;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

import static org.assertj.core.api.Assertions.assertThat;

@EnabledIfSystemProperty(named = "verification.postgres.url", matches = ".+")
class PostgresEmailVerificationMigrationTests {
    @Test
    void upgradesRepresentativeV26DataOnPostgres() throws Exception {
        String url = System.getProperty("verification.postgres.url");
        String username = System.getProperty("verification.postgres.username", "postgres");
        String password = System.getProperty("verification.postgres.password", "");

        Flyway.configure().dataSource(url, username, password).locations("classpath:db/migration")
                .target("26").load().migrate();
        try (Connection connection = DriverManager.getConnection(url, username, password)) {
            connection.createStatement().executeUpdate("""
                    INSERT INTO users
                        (full_name,email,password_hash,platform_role,account_status,created_at,updated_at)
                    VALUES
                        ('Pending','pending@iut-dhaka.edu','hash','STUDENT','PENDING_VERIFICATION',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),
                        ('Active','active@iut-dhaka.edu','hash','ALUMNI','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                    """);
            connection.createStatement().executeUpdate("""
                    INSERT INTO email_verification_tokens (user_id,token_hash,created_at,expires_at)
                    SELECT user_id, repeat('a',64), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '24 hours'
                    FROM users WHERE email='pending@iut-dhaka.edu'
                    """);
        }

        Flyway.configure().dataSource(url, username, password).locations("classpath:db/migration")
                .load().migrate();
        try (Connection connection = DriverManager.getConnection(url, username, password)) {
            assertThat(columnExists(connection, "token_hash")).isFalse();
            assertThat(columnExists(connection, "code_digest")).isTrue();
            assertThat(columnExists(connection, "code_salt")).isTrue();
            assertThat(columnExists(connection, "failed_attempts")).isTrue();
            assertThat(uniqueConstraintExists(connection, "code_digest")).isFalse();
            assertThat(checkConstraintExists(connection, "chk_verification_failed_attempts")).isTrue();

            ResultSet legacy = connection.createStatement().executeQuery("""
                    SELECT code_salt,failed_attempts,revoked_at
                    FROM email_verification_tokens
                    WHERE code_digest=repeat('a',64)
                    """);
            assertThat(legacy.next()).isTrue();
            assertThat(legacy.getString("code_salt")).isEqualTo("legacy-link-invalidated");
            assertThat(legacy.getInt("failed_attempts")).isZero();
            assertThat(legacy.getTimestamp("revoked_at")).isNotNull();

            ResultSet accounts = connection.createStatement().executeQuery(
                    "SELECT email,account_status FROM users ORDER BY email");
            assertThat(accounts.next()).isTrue();
            assertThat(accounts.getString("email")).isEqualTo("active@iut-dhaka.edu");
            assertThat(accounts.getString("account_status")).isEqualTo("ACTIVE");
            assertThat(accounts.next()).isTrue();
            assertThat(accounts.getString("email")).isEqualTo("pending@iut-dhaka.edu");
            assertThat(accounts.getString("account_status")).isEqualTo("PENDING_VERIFICATION");

            connection.createStatement().executeUpdate("""
                    INSERT INTO email_verification_tokens
                        (user_id,code_digest,code_salt,failed_attempts,created_at,expires_at)
                    SELECT user_id,repeat('b',64),repeat('s',43),0,
                           CURRENT_TIMESTAMP,CURRENT_TIMESTAMP + INTERVAL '10 minutes'
                    FROM users
                    """);
        }
    }

    private boolean columnExists(Connection connection, String column) throws Exception {
        try (ResultSet rows = connection.getMetaData().getColumns(null, "public",
                "email_verification_tokens", column)) {
            return rows.next();
        }
    }

    private boolean uniqueConstraintExists(Connection connection, String column) throws Exception {
        try (var statement = connection.prepareStatement("""
                SELECT 1
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_catalog=kcu.constraint_catalog
                 AND tc.constraint_schema=kcu.constraint_schema
                 AND tc.constraint_name=kcu.constraint_name
                WHERE tc.table_schema='public'
                  AND tc.table_name='email_verification_tokens'
                  AND tc.constraint_type='UNIQUE'
                  AND kcu.column_name=?
                """)) {
            statement.setString(1, column);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next();
            }
        }
    }

    private boolean checkConstraintExists(Connection connection, String constraint) throws Exception {
        try (var statement = connection.prepareStatement("""
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_schema='public' AND table_name='email_verification_tokens'
                  AND constraint_type='CHECK' AND constraint_name=?
                """)) {
            statement.setString(1, constraint);
            try (ResultSet rows = statement.executeQuery()) {
                return rows.next();
            }
        }
    }
}
