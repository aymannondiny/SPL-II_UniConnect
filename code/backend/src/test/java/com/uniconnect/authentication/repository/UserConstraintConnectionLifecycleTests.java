package com.uniconnect.authentication.repository;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class UserConstraintConnectionLifecycleTests {
    @Test
    void migratedConstraintsStillWorkAfterTheSchemaConnectionCloses() throws Exception {
        String url = "jdbc:h2:mem:user_constraint_lifecycle_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (Connection schema = DriverManager.getConnection(url, "sa", "")) {
            Flyway.configure().dataSource(new SingleConnectionDataSource(schema, true))
                    .locations("classpath:db/migration").load().migrate();
        }

        // Pool retirement must not leave constraints tied to the schema's closed JDBC session.
        try (Connection app = DriverManager.getConnection(url, "sa", "")) {
            try {
                for (String role : new String[]{"STUDENT", "ALUMNI", "SYSTEM_ADMIN"}) {
                    insertUser(app, role, "ACTIVE");
                }
                try (var query = app.createStatement();
                        var rows = query.executeQuery("select count(*) from users")) {
                    assertThat(rows.next()).isTrue();
                    assertThat(rows.getInt(1)).isEqualTo(3);
                }
                assertThatThrownBy(() -> insertUser(app, "INVALID_ROLE", "ACTIVE"))
                        .isInstanceOf(SQLException.class)
                        .extracting(error -> ((SQLException) error).getSQLState()).isEqualTo("23513");
                assertThatThrownBy(() -> insertUser(app, "STUDENT", "INVALID_STATUS"))
                        .isInstanceOf(SQLException.class)
                        .extracting(error -> ((SQLException) error).getSQLState()).isEqualTo("23513");

                insertSession(app, "PERSONAL");
                insertSession(app, "SYSTEM_ADMINISTRATION");
                assertThatThrownBy(() -> insertSession(app, "CLUB"))
                        .isInstanceOf(SQLException.class)
                        .extracting(error -> ((SQLException) error).getSQLState()).isEqualTo("23513");
            } finally {
                try (var shutdown = app.createStatement()) {
                    shutdown.execute("SHUTDOWN");
                }
            }
        }
    }

    private void insertUser(Connection app, String role, String status) throws SQLException {
        try (var insert = app.prepareStatement("""
                insert into users (full_name,email,password_hash,platform_role,account_status,created_at,updated_at)
                values ('Constraint test',?,'hash',?,?,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
                """)) {
            insert.setString(1, UUID.randomUUID() + "@example.test");
            insert.setString(2, role);
            insert.setString(3, status);
            insert.executeUpdate();
        }
    }

    private void insertSession(Connection app, String context) throws SQLException {
        try (var insert = app.prepareStatement("""
                insert into authenticated_sessions
                    (session_id,user_id,access_token_hash,refresh_token_hash,issued_at,expires_at,
                     access_expires_at,context_type,context_selected_at)
                select ?,user_id,?,?,CURRENT_TIMESTAMP,DATEADD('DAY',1,CURRENT_TIMESTAMP),
                       DATEADD('MINUTE',15,CURRENT_TIMESTAMP),?,CURRENT_TIMESTAMP
                from users where platform_role='SYSTEM_ADMIN'
                """)) {
            insert.setObject(1, UUID.randomUUID());
            insert.setString(2, UUID.randomUUID().toString().replace("-", "").repeat(2));
            insert.setString(3, UUID.randomUUID().toString().replace("-", "").repeat(2));
            insert.setString(4, context);
            insert.executeUpdate();
        }
    }
}
