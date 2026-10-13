package db.migration;

import java.util.ArrayList;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** V7 used unnamed checks, whose generated names differ between PostgreSQL and H2. */
public class V9__extend_notifications_for_clubs extends BaseJavaMigration {
    @Override
    public Integer getChecksum() { return 1; }
    @Override
    public void migrate(Context context) throws Exception {
        var connection = context.getConnection();
        var names = new ArrayList<String>();
        String query = "select tc.constraint_name, cc.check_clause from information_schema.table_constraints tc " +
                "join information_schema.check_constraints cc on tc.constraint_catalog=cc.constraint_catalog " +
                "and tc.constraint_schema=cc.constraint_schema and tc.constraint_name=cc.constraint_name " +
                "where tc.table_schema=? and tc.table_name='notifications' and tc.constraint_type='CHECK'";
        try (var statement = connection.prepareStatement(query)) {
            statement.setString(1, connection.getSchema());
            try (var rows = statement.executeQuery()) {
                while (rows.next()) {
                    String clause = rows.getString(2);
                    if (clause.contains("'CONNECTION_REQUESTED'") || clause.contains("'CONNECTION'")) names.add(rows.getString(1));
                }
            }
        }
        if (names.size() != 2) throw new IllegalStateException("Expected V7 notification type and reference checks");
        try (var statement = connection.createStatement()) {
            for (String name : names) statement.execute("ALTER TABLE notifications DROP CONSTRAINT \"" + name.replace("\"", "\"\"") + "\"");
            statement.execute("ALTER TABLE notifications ADD CONSTRAINT notification_type_allowed CHECK (type IN ('CONNECTION_REQUESTED','CONNECTION_ACCEPTED','CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED'))");
            statement.execute("ALTER TABLE notifications ADD CONSTRAINT notification_reference_allowed CHECK ((type IN ('CONNECTION_REQUESTED','CONNECTION_ACCEPTED') AND reference_type='CONNECTION') OR (type IN ('CLUB_ROLE_GRANTED','CLUB_ROLE_REVOKED') AND reference_type='CLUB'))");
        }
    }
}
