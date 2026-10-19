package com.uniconnect.reporting;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.UUID;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.datasource.SingleConnectionDataSource;

import static org.assertj.core.api.Assertions.*;

class ContentReportingMigrationTests {
    @Test
    void v15UpgradesPopulatedSchemaAndEnforcesReportingInvariants() throws Exception {
        String url=System.getProperty("content.reporting.migration.url","jdbc:h2:mem:content_reporting_upgrade_"+UUID.randomUUID()
                +";MODE=PostgreSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE");
        String username=System.getProperty("content.reporting.migration.username","sa");
        String password=System.getProperty("content.reporting.migration.password","");
        try(var connection=DriverManager.getConnection(url,username,password);var sql=connection.createStatement()){
            var source=new SingleConnectionDataSource(connection,true);
            Flyway.configure().dataSource(source).locations("classpath:db/migration").target("14").load().migrate();
            sql.executeUpdate("INSERT INTO users(user_id,full_name,platform_role,account_status,created_at,updated_at) VALUES "
                    +"(1,'Existing administrator','SYSTEM_ADMIN','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                    +"(2,'Existing reporter','STUDENT','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP),"
                    +"(3,'Existing target','STUDENT','SUSPENDED',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO moderation_actions(action_id,actor_id,target_user_id,action_type,reason,previous_state,new_state,created_at) "
                    +"VALUES (7,1,3,'SUSPEND_ACCOUNT','Retained reason','ACTIVE','SUSPENDED',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO audit_logs(moderation_action_id,actor_id,event_type,subject_type,subject_id,reason,previous_state_json,new_state_json,occurred_at) "
                    +"VALUES (7,1,'ACCOUNT_SUSPENDED','USER',3,'Retained reason','{}','{}',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) "
                    +"VALUES (2,'CONNECTION_REQUESTED','Existing','Retain me','CONNECTION',44,'existing-notification',CURRENT_TIMESTAMP)");

            Flyway.configure().dataSource(source).locations("classpath:db/migration").load().migrate();

            assertThat(queryInt(sql,"SELECT COUNT(*) FROM moderation_actions WHERE action_id=7")).isOne();
            assertThat(queryInt(sql,"SELECT COUNT(*) FROM notifications WHERE event_key='existing-notification'")).isOne();
            sql.executeUpdate("INSERT INTO content_reports(report_id,reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,"
                    +"target_owner_user_id,submitted_at,open_reporter_id,open_target_type,open_target_id) VALUES "
                    +"(10,2,'USER',3,'Concern','SUBMITTED','Existing target','{\"displayName\":\"Existing target\"}',3,CURRENT_TIMESTAMP,2,'USER',3)");
            sql.executeUpdate("INSERT INTO report_audit_logs(report_id,actor_id,event_type,new_status,occurred_at) "
                    +"VALUES (10,2,'SUBMITTED','SUBMITTED',CURRENT_TIMESTAMP)");
            assertThatThrownBy(()->sql.executeUpdate("INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,"
                    +"target_owner_user_id,submitted_at,open_reporter_id,open_target_type,open_target_id) VALUES "
                    +"(2,'USER',3,'Duplicate','SUBMITTED','Existing target','{}',3,CURRENT_TIMESTAMP,2,'USER',3)"))
                    .isInstanceOf(SQLException.class);

            sql.executeUpdate("UPDATE content_reports SET status='ACTION_TAKEN',reviewer_id=1,review_started_at=CURRENT_TIMESTAMP,"
                    +"resolved_at=CURRENT_TIMESTAMP,resolution_summary='Resolved',open_reporter_id=NULL,open_target_type=NULL,open_target_id=NULL WHERE report_id=10");
            sql.executeUpdate("INSERT INTO report_action_links(report_id,evidence_source,evidence_id,action_type,subject_type,subject_id,"
                    +"action_occurred_at,linked_by,linked_at) VALUES (10,'ACCOUNT_MODERATION',7,'SUSPEND_ACCOUNT','USER',3,CURRENT_TIMESTAMP,1,CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) "
                    +"VALUES (2,'REPORT_RESOLVED','Report resolved','Resolution available','REPORT',10,'report-resolution:10',CURRENT_TIMESTAMP)");
            sql.executeUpdate("INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,"
                    +"target_owner_user_id,submitted_at,open_reporter_id,open_target_type,open_target_id) VALUES "
                    +"(2,'USER',3,'Later concern','SUBMITTED','Existing target','{}',3,CURRENT_TIMESTAMP,2,'USER',3)");
            assertThat(queryInt(sql,"SELECT COUNT(*) FROM content_reports WHERE reporter_id=2 AND target_type='USER' AND target_id=3")).isEqualTo(2);
            assertThatThrownBy(()->sql.executeUpdate("INSERT INTO content_reports(reporter_id,target_type,target_id,reason,status,target_label,target_snapshot,"
                    +"submitted_at,open_reporter_id,open_target_type,open_target_id) VALUES "
                    +"(2,'PROJECT',8,'Bad target','SUBMITTED','Bad','{}',CURRENT_TIMESTAMP,2,'PROJECT',8)"))
                    .isInstanceOf(SQLException.class);
            assertThatThrownBy(()->sql.executeUpdate("INSERT INTO notifications(recipient_id,type,title,message,reference_type,reference_id,event_key,created_at) "
                    +"VALUES (2,'REPORT_RESOLVED','Bad','Bad','USER',10,'bad-report-reference',CURRENT_TIMESTAMP)"))
                    .isInstanceOf(SQLException.class);
        }
    }

    private int queryInt(java.sql.Statement sql,String query)throws SQLException{
        try(var rows=sql.executeQuery(query)){assertThat(rows.next()).isTrue();return rows.getInt(1);}
    }
}
