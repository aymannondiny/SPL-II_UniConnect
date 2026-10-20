package db.migration;

import java.util.ArrayList;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** Separates recoverable archives from terminal club deletions. */
public class V23__separate_club_archive_and_delete extends BaseJavaMigration {
    @Override public Integer getChecksum() { return 1; }

    @Override public void migrate(Context context) throws Exception {
        var connection = context.getConnection();
        var statusConstraints = new ArrayList<String>();
        String query = "select tc.constraint_name, cc.check_clause from information_schema.table_constraints tc " +
                "join information_schema.check_constraints cc on tc.constraint_catalog=cc.constraint_catalog " +
                "and tc.constraint_schema=cc.constraint_schema and tc.constraint_name=cc.constraint_name " +
                "where tc.table_schema=? and tc.table_name='clubs' and tc.constraint_type='CHECK'";
        try (var statement = connection.prepareStatement(query)) {
            statement.setString(1, connection.getSchema());
            try (var rows = statement.executeQuery()) {
                while (rows.next()) {
                    String clause = rows.getString(2);
                    if (clause.contains("'PUBLISHING_SUSPENDED'") && clause.contains("'REMOVED'"))
                        statusConstraints.add(rows.getString(1));
                }
            }
        }
        if (statusConstraints.size() != 1)
            throw new IllegalStateException("Expected the clubs status constraint from V10");

        try (var sql = connection.createStatement()) {
            sql.execute("ALTER TABLE clubs DROP CONSTRAINT \"" + statusConstraints.getFirst().replace("\"", "\"\"") + "\"");
            sql.execute("ALTER TABLE club_audit DROP CONSTRAINT club_audit_transition_shape");

            // Prior releases used REMOVED for the archive action. Keep those records recoverable.
            sql.execute("UPDATE club_audit SET action='CLUB_ARCHIVED', new_state='ARCHIVED' " +
                    "WHERE action='CLUB_REMOVED' AND new_state='REMOVED'");
            sql.execute("UPDATE club_audit SET previous_state='ARCHIVED' " +
                    "WHERE action='CLUB_ARCHIVE_RESTORED' AND previous_state='REMOVED'");
            sql.execute("UPDATE clubs SET status='ARCHIVED' WHERE status='REMOVED'");
            sql.execute("UPDATE report_action_links SET action_type='CLUB_ARCHIVED' " +
                    "WHERE evidence_source='CLUB_LIFECYCLE' AND action_type='CLUB_REMOVED'");

            sql.execute("ALTER TABLE clubs ADD CONSTRAINT club_status_allowed CHECK (status IN ('ACTIVE','PUBLISHING_SUSPENDED','ARCHIVED','REMOVED'))");
            sql.execute("ALTER TABLE club_audit ADD CONSTRAINT club_audit_transition_shape CHECK (" +
                    "(action IN ('CLUB_CREATED','ROLE_GRANTED','ROLE_REVOKED','ADMINISTRATOR_REPLACED') AND target_assignment_id IS NOT NULL AND previous_state IS NULL AND new_state IS NULL) OR " +
                    "(target_assignment_id IS NULL AND actor_assignment_id IS NULL AND previous_state IS NOT NULL AND new_state IS NOT NULL AND " +
                    "((action='CLUB_PUBLISHING_SUSPENDED' AND previous_state='ACTIVE' AND new_state='PUBLISHING_SUSPENDED') OR " +
                    "(action='CLUB_PUBLISHING_RESTORED' AND previous_state='PUBLISHING_SUSPENDED' AND new_state='ACTIVE') OR " +
                    "(action='CLUB_ARCHIVED' AND previous_state IN ('ACTIVE','PUBLISHING_SUSPENDED') AND new_state='ARCHIVED') OR " +
                    "(action='CLUB_ARCHIVE_RESTORED' AND previous_state='ARCHIVED' AND new_state IN ('ACTIVE','PUBLISHING_SUSPENDED')) OR " +
                    "(action='CLUB_REMOVED' AND previous_state IN ('ACTIVE','PUBLISHING_SUSPENDED','ARCHIVED') AND new_state='REMOVED'))))");
        }
    }
}
