package com.uniconnect.career;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CareerBoardMigrationTests {
    @Test
    void v18UpgradesPopulatedV17SchemaWithoutChangingExistingDataOrNotificationRules() throws Exception {
        String url = System.getProperty("career.migration.url", "jdbc:h2:mem:career_upgrade_" + UUID.randomUUID()
                + ";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE");
        String username = System.getProperty("career.migration.username", "sa");
        String password = System.getProperty("career.migration.password", "");
        try (var connection = DriverManager.getConnection(url, username, password);
                var sql = connection.createStatement()) {
            var source = new SingleConnectionDataSource(connection, true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration").target("17").load().migrate();
            sql.executeUpdate("INSERT INTO users(user_id,full_name,email,platform_role,account_status,created_at,updated_at) VALUES "
                    + "(1,'Existing alumni','alumni@example.test','ALUMNI','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                    + "(2,'Existing student','student@example.test','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO skills(skill_id,name) VALUES (7,'java')");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) VALUES "
                    + "(2,'NEW_MESSAGE','Existing message','Retain me','CONVERSATION',66,'career-existing-message',CURRENT_TIMESTAMP),"
                    + "(2,'REPORT_RESOLVED','Existing report','Retain me','REPORT',77,'career-existing-report',CURRENT_TIMESTAMP)");

            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();

            assertThat(queryInt(sql, "select count(*) from notifications where event_key like 'career-existing-%'"))
                    .isEqualTo(2);
            sql.executeUpdate("INSERT INTO career_job_posts(job_post_id,author_user_id,title,company_name,description,qualifications,employment_type,work_mode,application_url,application_deadline,status,posted_at,updated_at) "
                    + "VALUES (10,1,'Engineer','Example','Description','Qualifications','FULL_TIME','REMOTE','https://example.test/apply',DATE '2026-10-20','PUBLISHED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO career_job_skills(job_post_id,skill_id,required) VALUES (10,7,true)");
            sql.executeUpdate("INSERT INTO career_saved_jobs(student_user_id,job_post_id,saved_at) VALUES (2,10,CURRENT_TIMESTAMP)");
            assertThatThrownBy(() -> sql.executeUpdate(
                    "INSERT INTO career_saved_jobs(student_user_id,job_post_id,saved_at) VALUES (2,10,CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate(
                    "INSERT INTO career_job_posts(author_user_id,title,company_name,description,qualifications,employment_type,work_mode,application_deadline,status,posted_at,updated_at) "
                            + "VALUES (1,'Bad','Example','Description','Qualifications','FULL_TIME','REMOTE',DATE '2026-10-20','PUBLISHED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(() -> sql.executeUpdate(
                    "UPDATE career_job_posts SET status='CLOSED' WHERE job_post_id=10"))
                    .isInstanceOf(SQLException.class);
        }
    }

    private int queryInt(java.sql.Statement sql, String query) throws SQLException {
        try (var rows = sql.executeQuery(query)) {
            assertThat(rows.next()).isTrue();
            return rows.getInt(1);
        }
    }
}
