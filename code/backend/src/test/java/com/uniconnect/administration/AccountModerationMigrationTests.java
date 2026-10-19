package com.uniconnect.administration;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import static org.assertj.core.api.Assertions.*;

class AccountModerationMigrationTests {
    @Test
    void v14UpgradesPopulatedSchemaWithoutLosingExistingRecords() throws Exception {
        String url = System.getProperty("account.moderation.migration.url",
                "jdbc:h2:mem:account_moderation_upgrade_" + UUID.randomUUID()
                        + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE");
        String username = System.getProperty("account.moderation.migration.username", "sa");
        String password = System.getProperty("account.moderation.migration.password", "");
        try (var connection = DriverManager.getConnection(url, username, password); var sql = connection.createStatement()) {
            var source = new SingleConnectionDataSource(connection, true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration").target("13").load().migrate();
            sql.executeUpdate("INSERT INTO users(user_id,full_name,platform_role,account_status,created_at,updated_at) VALUES "
                    + "(1,'Existing administrator','SYSTEM_ADMIN','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                    + "(2,'Existing member','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO authenticated_sessions(session_id,user_id,access_token_hash,refresh_token_hash,issued_at,expires_at,access_expires_at,context_type,context_selected_at) VALUES "
                    + "('00000000-0000-0000-0000-000000000001',2,'existing-access','existing-refresh',CURRENT_TIMESTAMP,TIMESTAMP '2099-01-01 00:00:00',TIMESTAMP '2099-01-01 00:00:00','PERSONAL',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES "
                    + "(2,'CONNECTION_REQUESTED','Existing','Retain requested','CONNECTION',91,'legacy-requested',CURRENT_TIMESTAMP),"
                    + "(2,'CONNECTION_ACCEPTED','Existing','Retain accepted','CONNECTION',92,'legacy-accepted',CURRENT_TIMESTAMP),"
                    + "(2,'CLUB_ROLE_GRANTED','Existing','Retain granted','CLUB',93,'legacy-granted',CURRENT_TIMESTAMP),"
                    + "(2,'CLUB_ROLE_REVOKED','Existing','Retain revoked','CLUB',94,'legacy-revoked',CURRENT_TIMESTAMP),"
                    + "(2,'PUBLISHING_SUSPENDED','Existing','Retain suspended','CLUB',95,'legacy-suspended',CURRENT_TIMESTAMP),"
                    + "(2,'PUBLISHING_RESTORED','Existing','Retain restored','CLUB',96,'legacy-restored',CURRENT_TIMESTAMP)");

            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();

            try (var rows = sql.executeQuery("SELECT u.full_name,s.access_token_hash,n.message FROM users u "
                    + "JOIN authenticated_sessions s ON s.user_id=u.user_id "
                    + "JOIN notifications n ON n.recipient_id=u.user_id WHERE u.user_id=2")) {
                assertThat(rows.next()).isTrue();
                assertThat(rows.getString(1)).isEqualTo("Existing member");
                assertThat(rows.getString(2)).isEqualTo("existing-access");
                assertThat(rows.getString(3)).isIn("Retain requested", "Retain accepted", "Retain granted",
                        "Retain revoked", "Retain suspended", "Retain restored");
            }
            try (var retained = sql.executeQuery("SELECT COUNT(*) FROM notifications WHERE event_key LIKE 'legacy-%'")) {
                assertThat(retained.next()).isTrue();
                assertThat(retained.getInt(1)).isEqualTo(6);
            }

            sql.executeUpdate("INSERT INTO moderation_actions(action_id,actor_id,target_user_id,action_type,reason,previous_state,new_state,created_at) "
                    + "VALUES (1,1,2,'SUSPEND_ACCOUNT','Private reason','ACTIVE','SUSPENDED',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO audit_logs(moderation_action_id,actor_id,event_type,subject_type,subject_id,reason,previous_state_json,new_state_json,occurred_at) "
                    + "VALUES (1,1,'ACCOUNT_SUSPENDED','USER',2,'Private reason','{\"accountStatus\":\"ACTIVE\"}','{\"accountStatus\":\"SUSPENDED\"}',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) "
                    + "VALUES (2,'ACCOUNT_SUSPENDED','Account update','Generic text','USER',1,'account-moderation:1',CURRENT_TIMESTAMP)");

            assertThatThrownBy(() -> sql.executeUpdate("INSERT INTO moderation_actions(actor_id,target_user_id,action_type,reason,previous_state,new_state,created_at) "
                    + "VALUES (1,2,'SUSPEND_ACCOUNT','Bad transition','SUSPENDED','ACTIVE',CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE notifications SET reference_type='CLUB' WHERE event_key='account-moderation:1'"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE notifications SET reference_type='USER' WHERE event_key='legacy-suspended'"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("INSERT INTO audit_logs(moderation_action_id,actor_id,event_type,subject_type,subject_id,reason,previous_state_json,new_state_json,occurred_at) "
                    + "VALUES (1,1,'ACCOUNT_SUSPENDED','USER',2,'Duplicate','{}','{}',CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
        }
    }
}
