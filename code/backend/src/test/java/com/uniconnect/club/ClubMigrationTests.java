package com.uniconnect.club;

import java.sql.DriverManager;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class ClubMigrationTests {
    @Test
    void upgradingExistingDatabasePreservesNotificationsAndInitializesSessionContext() throws Exception {
        String url = "jdbc:h2:mem:club_upgrade_" + UUID.randomUUID() + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (var connection = DriverManager.getConnection(url, "sa", ""); var sql = connection.createStatement()) {
            var dataSource = new SingleConnectionDataSource(connection, true);

            Flyway.configure()
                    .dataSource(dataSource)
                    .locations("classpath:db/migration")
                    .target("8")
                    .load()
                    .migrate();
            sql.executeUpdate("INSERT INTO users(user_id, full_name, platform_role, account_status, created_at, updated_at) VALUES (1, 'Existing member', 'STUDENT', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES (1,'CONNECTION_REQUESTED','Request','Existing notification','CONNECTION',1,'old-event',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO authenticated_sessions(session_id,user_id,access_token_hash,refresh_token_hash,issued_at,expires_at,access_expires_at) VALUES ('00000000-0000-0000-0000-000000000001',1,'old-access','old-refresh',TIMESTAMP '2026-10-01 10:00:00',TIMESTAMP '2026-10-15 10:00:00',TIMESTAMP '2026-10-02 10:00:00')");
            Flyway.configure()
                    .dataSource(dataSource)
                    .locations("classpath:db/migration")
                    .load()
                    .migrate();
            try (var rows = sql.executeQuery("SELECT context_type, context_assignment_id, context_selected_at=issued_at AS initialized FROM authenticated_sessions")) {
                assertThat(rows.next()).isTrue();
                assertThat(rows.getString(1)).isEqualTo("PERSONAL");
                assertThat(rows.getObject(2)).isNull();
                assertThat(rows.getBoolean(3)).isTrue();
            }
            try (var rows = sql.executeQuery("SELECT message FROM notifications WHERE event_key='old-event'")) {
                assertThat(rows.next()).isTrue();
                assertThat(rows.getString(1)).isEqualTo("Existing notification");
            }
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES (1,'CLUB_ROLE_GRANTED','Granted','Club access granted','CLUB',1,'new-event',CURRENT_TIMESTAMP)");
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE notifications SET reference_type='CONNECTION' WHERE event_key='new-event'")).isInstanceOf(java.sql.SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE notifications SET reference_type='CLUB' WHERE event_key='old-event'")).isInstanceOf(java.sql.SQLException.class);
        }
    }
}
