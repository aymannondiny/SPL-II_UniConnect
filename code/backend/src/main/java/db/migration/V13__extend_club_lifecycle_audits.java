package db.migration;

import java.util.ArrayList;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** Extends V10's unnamed action check without changing an applied migration. */
public class V13__extend_club_lifecycle_audits extends BaseJavaMigration {
    @Override public Integer getChecksum() { return 1; }
    @Override public void migrate(Context context) throws Exception {
        var connection = context.getConnection();
        var names = new ArrayList<String>();
        String query = "select tc.constraint_name, cc.check_clause from information_schema.table_constraints tc " +
                "join information_schema.check_constraints cc on tc.constraint_catalog=cc.constraint_catalog " +
                "and tc.constraint_schema=cc.constraint_schema and tc.constraint_name=cc.constraint_name " +
                "where tc.table_schema=? and tc.table_name='club_audit' and tc.constraint_type='CHECK'";
        try (var statement = connection.prepareStatement(query)) {
            statement.setString(1, connection.getSchema());
            try (var rows = statement.executeQuery()) {
                while (rows.next()) if (rows.getString(2).contains("'CLUB_CREATED'")) names.add(rows.getString(1));
            }
        }
        if (names.size() != 1) throw new IllegalStateException("Expected V10 club audit action check");
        try (var sql = connection.createStatement()) {
            sql.execute("ALTER TABLE club_audit DROP CONSTRAINT \"" + names.getFirst().replace("\"", "\"\"") + "\"");
            sql.execute("ALTER TABLE club_audit ALTER COLUMN target_assignment_id DROP NOT NULL");
            sql.execute("ALTER TABLE club_audit ADD COLUMN previous_state VARCHAR(30)");
            sql.execute("ALTER TABLE club_audit ADD COLUMN new_state VARCHAR(30)");
            sql.execute("ALTER TABLE club_audit ADD CONSTRAINT club_audit_transition_shape CHECK (" +
                    "(action IN ('CLUB_CREATED','ROLE_GRANTED','ROLE_REVOKED','ADMINISTRATOR_REPLACED') AND target_assignment_id IS NOT NULL AND previous_state IS NULL AND new_state IS NULL) OR " +
                    "(target_assignment_id IS NULL AND actor_assignment_id IS NULL AND previous_state IS NOT NULL AND new_state IS NOT NULL AND " +
                    "((action='CLUB_PUBLISHING_SUSPENDED' AND previous_state='ACTIVE' AND new_state='PUBLISHING_SUSPENDED') OR " +
                    "(action='CLUB_PUBLISHING_RESTORED' AND previous_state='PUBLISHING_SUSPENDED' AND new_state='ACTIVE') OR " +
                    "(action='CLUB_REMOVED' AND previous_state IN ('ACTIVE','PUBLISHING_SUSPENDED') AND new_state='REMOVED'))))");
            sql.execute("ALTER TABLE notifications DROP CONSTRAINT notification_type_allowed");
            sql.execute("ALTER TABLE notifications DROP CONSTRAINT notification_reference_allowed");
            sql.execute("ALTER TABLE notifications ADD CONSTRAINT notification_type_allowed CHECK (type IN ('CONNECTION_REQUESTED','CONNECTION_ACCEPTED','CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED','PUBLISHING_SUSPENDED','PUBLISHING_RESTORED'))");
            sql.execute("ALTER TABLE notifications ADD CONSTRAINT notification_reference_allowed CHECK ((type IN ('CONNECTION_REQUESTED','CONNECTION_ACCEPTED') AND reference_type='CONNECTION') OR (type IN ('CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED','PUBLISHING_SUSPENDED','PUBLISHING_RESTORED') AND reference_type='CLUB'))");
        }
    }
}
