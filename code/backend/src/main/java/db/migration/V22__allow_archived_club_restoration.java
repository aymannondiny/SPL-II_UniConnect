package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** Allows a retained club archive to transition back to its recorded prior state. */
public class V22__allow_archived_club_restoration extends BaseJavaMigration {
    @Override public Integer getChecksum() { return 1; }

    @Override public void migrate(Context context) throws Exception {
        try (var sql = context.getConnection().createStatement()) {
            sql.execute("ALTER TABLE club_audit DROP CONSTRAINT club_audit_transition_shape");
            sql.execute("ALTER TABLE club_audit ADD CONSTRAINT club_audit_transition_shape CHECK (" +
                    "(action IN ('CLUB_CREATED','ROLE_GRANTED','ROLE_REVOKED','ADMINISTRATOR_REPLACED') AND target_assignment_id IS NOT NULL AND previous_state IS NULL AND new_state IS NULL) OR " +
                    "(target_assignment_id IS NULL AND actor_assignment_id IS NULL AND previous_state IS NOT NULL AND new_state IS NOT NULL AND " +
                    "((action='CLUB_PUBLISHING_SUSPENDED' AND previous_state='ACTIVE' AND new_state='PUBLISHING_SUSPENDED') OR " +
                    "(action='CLUB_PUBLISHING_RESTORED' AND previous_state='PUBLISHING_SUSPENDED' AND new_state='ACTIVE') OR " +
                    "(action='CLUB_REMOVED' AND previous_state IN ('ACTIVE','PUBLISHING_SUSPENDED') AND new_state='REMOVED') OR " +
                    "(action='CLUB_ARCHIVE_RESTORED' AND previous_state='REMOVED' AND new_state IN ('ACTIVE','PUBLISHING_SUSPENDED')))))");
        }
    }
}
