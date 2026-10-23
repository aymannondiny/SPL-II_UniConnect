package db.migration;

import java.util.ArrayList;
import java.util.Locale;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

/** Adds project and career-post targets without changing the applied V17 migration. */
public class V25__extend_reporting_targets extends BaseJavaMigration {
    @Override public Integer getChecksum() { return 1; }

    @Override
    public void migrate(Context context) throws Exception {
        var connection = context.getConnection();
        var targetConstraints = new ArrayList<String>();
        String query = "select tc.constraint_name, cc.check_clause from information_schema.table_constraints tc "
                + "join information_schema.check_constraints cc on tc.constraint_catalog=cc.constraint_catalog "
                + "and tc.constraint_schema=cc.constraint_schema and tc.constraint_name=cc.constraint_name "
                + "where tc.table_schema=? and lower(tc.table_name)='content_reports' and tc.constraint_type='CHECK'";
        try (var statement = connection.prepareStatement(query)) {
            statement.setString(1, connection.getSchema());
            try (var rows = statement.executeQuery()) {
                while (rows.next()) {
                    String clause = rows.getString(2).toUpperCase(Locale.ROOT);
                    if (clause.contains("TARGET_TYPE") && clause.contains("'USER'")
                            && clause.contains("'CHAT_MESSAGE'")) {
                        targetConstraints.add(rows.getString(1));
                    }
                }
            }
        }
        if (targetConstraints.size() != 1) {
            throw new IllegalStateException("Expected the content_reports target_type constraint from V17");
        }
        String constraint = targetConstraints.getFirst().replace("\"", "\"\"");
        try (var sql = connection.createStatement()) {
            sql.execute("ALTER TABLE content_reports DROP CONSTRAINT \"" + constraint + "\"");
            sql.execute("ALTER TABLE content_reports ADD CONSTRAINT report_target_type_allowed CHECK (target_type IN ("
                    + "'USER','CLUB','ANNOUNCEMENT','EVENT','CHAT_MESSAGE','PROJECT','CAREER_POST'))");
        }
    }
}
