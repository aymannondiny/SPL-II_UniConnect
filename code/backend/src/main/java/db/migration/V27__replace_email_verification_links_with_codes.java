package db.migration;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

public class V27__replace_email_verification_links_with_codes extends BaseJavaMigration {
    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        dropLegacyDigestUniqueness(connection);
        try (Statement sql = connection.createStatement()) {
            sql.execute("ALTER TABLE email_verification_tokens RENAME COLUMN token_hash TO code_digest");
            sql.execute("ALTER TABLE email_verification_tokens ADD COLUMN code_salt VARCHAR(43)");
            sql.execute("ALTER TABLE email_verification_tokens ADD COLUMN failed_attempts INTEGER DEFAULT 0 NOT NULL");
            sql.execute("""
                    UPDATE email_verification_tokens
                    SET revoked_at = COALESCE(revoked_at, CURRENT_TIMESTAMP),
                        code_salt = 'legacy-link-invalidated'
                    WHERE code_salt IS NULL
                    """);
            sql.execute("ALTER TABLE email_verification_tokens ALTER COLUMN code_salt SET NOT NULL");
            sql.execute("""
                    ALTER TABLE email_verification_tokens
                    ADD CONSTRAINT chk_verification_failed_attempts
                    CHECK (failed_attempts BETWEEN 0 AND 5)
                    """);
        }
    }

    private void dropLegacyDigestUniqueness(Connection connection) throws SQLException {
        String constraint = null;
        try (Statement sql = connection.createStatement(); ResultSet rows = sql.executeQuery("""
                SELECT tc.constraint_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                  ON tc.constraint_catalog = kcu.constraint_catalog
                 AND tc.constraint_schema = kcu.constraint_schema
                 AND tc.constraint_name = kcu.constraint_name
                WHERE LOWER(tc.table_name) = 'email_verification_tokens'
                  AND tc.constraint_type = 'UNIQUE'
                  AND LOWER(kcu.column_name) = 'token_hash'
                """)) {
            if (rows.next()) constraint = rows.getString(1);
        }
        if (constraint == null) {
            throw new SQLException("Legacy verification digest uniqueness constraint was not found");
        }
        String quote = connection.getMetaData().getIdentifierQuoteString().strip();
        if (quote.isEmpty()) quote = "\"";
        String safeConstraint = quote + constraint.replace(quote, quote + quote) + quote;
        try (Statement sql = connection.createStatement()) {
            sql.execute("ALTER TABLE email_verification_tokens DROP CONSTRAINT " + safeConstraint);
        }
    }
}
