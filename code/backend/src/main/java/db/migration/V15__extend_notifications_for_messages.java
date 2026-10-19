package db.migration;

import java.sql.Statement;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** Extends V14's notification constraints with direct-message notifications. */
public class V15__extend_notifications_for_messages extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        try (Statement statement = context.getConnection().createStatement()) {
            statement.execute("ALTER TABLE notifications DROP CONSTRAINT notification_type_allowed");
            statement.execute("ALTER TABLE notifications DROP CONSTRAINT notification_reference_allowed");
            statement.execute("ALTER TABLE notifications ADD CONSTRAINT notification_type_allowed CHECK (type IN "
                    + "('CONNECTION_REQUESTED','CONNECTION_ACCEPTED','ACCOUNT_SUSPENDED','ACCOUNT_REACTIVATED',"
                    + "'CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED',"
                    + "'PUBLISHING_SUSPENDED','PUBLISHING_RESTORED','NEW_MESSAGE'))");
            statement.execute("ALTER TABLE notifications ADD CONSTRAINT notification_reference_allowed CHECK ("
                    + "(type IN ('CONNECTION_REQUESTED','CONNECTION_ACCEPTED') AND reference_type='CONNECTION') OR "
                    + "(type IN ('ACCOUNT_SUSPENDED','ACCOUNT_REACTIVATED') AND reference_type='USER') OR "
                    + "(type IN ('CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED','PUBLISHING_SUSPENDED','PUBLISHING_RESTORED') "
                    + "AND reference_type='CLUB') OR "
                    + "(type='NEW_MESSAGE' AND reference_type='CONVERSATION'))");
        }
    }
}
