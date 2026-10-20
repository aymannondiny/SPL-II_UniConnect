package db.migration;

import java.sql.Connection;
import java.util.ArrayList;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** V10's single-administrator unique keys are removed without changing the applied migration. */
public class V20__allow_multiple_club_administrators extends BaseJavaMigration {
    @Override public Integer getChecksum() { return 1; }

    @Override public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        var constraints = new ArrayList<String>();
        String query = "select tc.constraint_name, kcu.column_name from information_schema.table_constraints tc " +
                "join information_schema.key_column_usage kcu on tc.constraint_catalog=kcu.constraint_catalog " +
                "and tc.constraint_schema=kcu.constraint_schema and tc.constraint_name=kcu.constraint_name " +
                "where tc.table_schema=? and lower(tc.table_name)='club_role_assignments' and tc.constraint_type='UNIQUE' " +
                "and lower(kcu.column_name) in ('administrator_club_id','administrator_user_id')";
        try (var statement = connection.prepareStatement(query)) {
            statement.setString(1, connection.getSchema());
            try (var rows = statement.executeQuery()) {
                while (rows.next()) if (!constraints.contains(rows.getString(1))) constraints.add(rows.getString(1));
            }
        }
        try (var statement = connection.createStatement()) {
            for (String constraint : constraints)
                statement.execute("alter table club_role_assignments drop constraint \"" + constraint.replace("\"", "\"\"") + "\"");
            statement.execute("create index if not exists idx_club_administrators on club_role_assignments(administrator_club_id,administrator_user_id)");
        }
    }
}
