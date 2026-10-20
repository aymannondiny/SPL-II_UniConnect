package com.uniconnect.project;

import java.sql.*;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;
import static org.assertj.core.api.Assertions.*;

class ProjectTeammateMigrationTests {
    @Test void v19UpgradesPopulatedV18AndPreservesEveryExistingNotificationCombination() throws Exception {
        String url = System.getProperty("project.migration.url", "jdbc:h2:mem:project_upgrade_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE");
        String username = System.getProperty("project.migration.username", "sa");
        String password = System.getProperty("project.migration.password", "");
        try (var connection = DriverManager.getConnection(url, username, password); var sql = connection.createStatement()) {
            var source = new SingleConnectionDataSource(connection, true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration").target("18").load().migrate();
            sql.executeUpdate("INSERT INTO users(user_id,full_name,platform_role,account_status,created_at,updated_at) VALUES "
                    + "(1,'Creator','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                    + "(2,'Applicant','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            String[][] combinations = {
                    {"CONNECTION_REQUESTED","CONNECTION"},{"CONNECTION_ACCEPTED","CONNECTION"},
                    {"CLUB_ROLE_GRANTED","CLUB"},{"CLUB_ROLE_REVOKED","CLUB"},
                    {"PUBLISHING_SUSPENDED","CLUB"},{"PUBLISHING_RESTORED","CLUB"},
                    {"NEW_MESSAGE","CONVERSATION"},{"ACCOUNT_SUSPENDED","USER"},
                    {"ACCOUNT_REACTIVATED","USER"},{"REPORT_RESOLVED","REPORT"}
            };
            for (int i = 0; i < combinations.length; i++) sql.executeUpdate(
                    "INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES "
                            + "(2,'" + combinations[i][0] + "','Existing','Retain','" + combinations[i][1]
                            + "'," + (100 + i) + ",'project-existing-" + i + "',CURRENT_TIMESTAMP)");
            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();
            assertThat(queryInt(sql, "select count(*) from notifications where event_key like 'project-existing-%'"))
                    .isEqualTo(combinations.length);
            sql.executeUpdate("INSERT INTO skills(skill_id,name) VALUES (1,'java')");
            sql.executeUpdate("INSERT INTO teammate_projects(project_id,creator_user_id,title,description,team_size_limit,application_deadline,status,created_at,updated_at) "
                    + "VALUES (10,1,'Project','Description',2,DATE '2026-10-21','OPEN',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO teammate_project_memberships(project_id,member_user_id,role,creator_project_id,joined_at) VALUES (10,1,'CREATOR',10,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO teammate_project_applications(project_id,applicant_user_id,status,applied_at) VALUES (10,2,'PENDING',CURRENT_TIMESTAMP)");
            assertThatThrownBy(() -> sql.executeUpdate("INSERT INTO teammate_project_applications(project_id,applicant_user_id,status,applied_at) VALUES (10,2,'PENDING',CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate("UPDATE teammate_projects SET team_size_limit=1 WHERE project_id=10"))
                    .isInstanceOf(SQLException.class);
        }
    }
    private int queryInt(Statement sql, String query) throws SQLException {
        try (var rows = sql.executeQuery(query)) { assertThat(rows.next()).isTrue(); return rows.getInt(1); }
    }
}
