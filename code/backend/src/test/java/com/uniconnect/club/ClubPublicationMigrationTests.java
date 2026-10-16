package com.uniconnect.club;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import static org.assertj.core.api.Assertions.*;

class ClubPublicationMigrationTests {
    @Test
    void v12PreservesExistingClubContextAndEnforcesPublicationRelationships() throws Exception {
        String url = "jdbc:h2:mem:publication_upgrade_" + UUID.randomUUID() + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (var connection = DriverManager.getConnection(url, "sa", ""); var sql = connection.createStatement()) {
            var source = new SingleConnectionDataSource(connection, true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration").target("11").load().migrate();
            sql.executeUpdate("INSERT INTO users(user_id,full_name,platform_role,account_status,created_at,updated_at) VALUES (1,'Existing administrator','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),(2,'Other user','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO clubs(club_id,club_name,name_key,category,description,status,created_at,updated_at) VALUES (1,'Existing club','existing club','Technology','Retain this','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO club_role_assignments(assignment_id,club_id,user_id,role,assigned_by,assigned_at,current_club_id,current_user_id,administrator_club_id,administrator_user_id) VALUES (1,1,1,'CLUB_ADMINISTRATOR',1,CURRENT_TIMESTAMP,1,1,1,1)");
            sql.executeUpdate("INSERT INTO authenticated_sessions(session_id,user_id,access_token_hash,refresh_token_hash,issued_at,expires_at,access_expires_at,context_type,context_assignment_id,context_selected_at) VALUES ('00000000-0000-0000-0000-000000000001',1,'access','refresh',CURRENT_TIMESTAMP,TIMESTAMP '2099-01-01 00:00:00',TIMESTAMP '2099-01-01 00:00:00','CLUB',1,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES (1,'CLUB_ROLE_GRANTED','Granted','Existing notification','CLUB',1,'existing-club',CURRENT_TIMESTAMP)");
            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();
            try (var rows = sql.executeQuery("SELECT s.context_type,s.context_assignment_id,c.description,n.message FROM authenticated_sessions s JOIN club_role_assignments a ON a.assignment_id=s.context_assignment_id JOIN clubs c ON c.club_id=a.club_id JOIN notifications n ON n.recipient_id=s.user_id")) {
                assertThat(rows.next()).isTrue(); assertThat(rows.getString(1)).isEqualTo("CLUB"); assertThat(rows.getLong(2)).isEqualTo(1);
                assertThat(rows.getString(3)).isEqualTo("Retain this"); assertThat(rows.getString(4)).isEqualTo("Existing notification");
            }
            sql.executeUpdate("INSERT INTO club_announcements(announcement_id,club_id,author_user_id,author_assignment_id,title,content,priority,status,created_at,updated_at) VALUES (1,1,1,1,'Draft','Content','NORMAL','UNPUBLISHED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE club_announcements SET author_user_id=2 WHERE announcement_id=1")).isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE club_announcements SET status='PUBLISHED' WHERE announcement_id=1")).isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE club_announcements SET status='REMOVED' WHERE announcement_id=1")).isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("INSERT INTO club_events(club_id,author_user_id,author_assignment_id,title,description,starts_at,ends_at,status,published_at,updated_at) VALUES (1,1,1,'Bad interval','Content',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,'PUBLISHED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)")).isInstanceOf(SQLException.class);
            sql.executeUpdate("INSERT INTO club_publication_audit(club_id,announcement_id,actor_user_id,actor_assignment_id,action,after_snapshot,created_at) VALUES (1,1,1,1,'CREATED','{}',CURRENT_TIMESTAMP)");
            assertThatThrownBy(() -> sql.executeUpdate("DELETE FROM club_announcements WHERE announcement_id=1")).isInstanceOf(SQLException.class);
        }
    }
}
