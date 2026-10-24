package com.uniconnect.mentorship;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfSystemProperty;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

@EnabledIfSystemProperty(named = "postgres.migration.url", matches = ".+")
class MentorshipMigrationUpgradeTests {

    @Test
    void populatedPostgresUpgradePreservesHistoryAndBackfillsOccurrences() throws Exception {
        String url = System.getProperty("postgres.migration.url");
        String username = System.getProperty("postgres.migration.username", "postgres");
        String password = System.getProperty("postgres.migration.password", "");
        Flyway baseline = Flyway.configure().dataSource(url, username, password)
                .locations("classpath:db/migration").cleanDisabled(false).target("25").load();
        baseline.clean();
        baseline.migrate();

        try (Connection connection = DriverManager.getConnection(url, username, password);
             Statement sql = connection.createStatement()) {
            sql.executeUpdate("""
                    INSERT INTO users(user_id, full_name, email, password_hash, platform_role, account_status, created_at, updated_at)
                    VALUES (9101, 'Legacy Mentor', 'legacy-mentor@example.test', 'x', 'STUDENT', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                           (9102, 'Legacy Mentee', 'legacy-mentee@example.test', 'x', 'ALUMNI', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                           (9103, 'Active Legacy Mentee', 'active-legacy-mentee@example.test', 'x', 'STUDENT', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """);
            sql.executeUpdate("""
                    INSERT INTO mentor_profiles(mentor_profile_id, user_id, mentoring_bio, status, registered_at, updated_at)
                    VALUES (9201, 9101, 'Legacy populated migration mentor', 'AVAILABLE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """);
            sql.executeUpdate("""
                    INSERT INTO mentorship_slots(slot_id, mentor_profile_id, topic, description, schedule_type, start_date,
                        start_time, end_time, recurrence_end_date, mode, capacity, current_mentee_count, status, created_at, updated_at)
                    VALUES
                      (9301, 9201, 'Unbounded legacy', 'Preserve the historic twelve-meeting interpretation.', 'WEEKLY', DATE '2026-01-05', TIME '09:00', TIME '10:00', NULL, 'ONLINE', 5, 4, 'FULL', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                      (9302, 9201, 'Closed legacy', 'Manual closure must survive migration.', 'BIWEEKLY', DATE '2026-02-02', TIME '11:00', TIME '12:00', DATE '2026-06-30', 'ONLINE', 5, 0, 'CLOSED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
                      (9303, 9201, 'One time legacy', 'A one-time meeting remains singular.', 'ONE_TIME', DATE '2026-03-03', TIME '13:00', TIME '14:00', NULL, 'ONLINE', 5, 0, 'OPEN', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                    """);
            sql.executeUpdate("""
                    INSERT INTO mentorship_occurrences(occurrence_id, slot_id, starts_at, ends_at)
                    VALUES (9401, 9301, TIMESTAMP '2026-01-05 09:00:00', TIMESTAMP '2026-01-05 10:00:00'),
                           (9402, 9301, TIMESTAMP '2026-01-05 09:00:00', TIMESTAMP '2026-01-05 10:30:00')
                    """);
            sql.executeUpdate("""
                    INSERT INTO mentorship_enrollments(enrollment_id, slot_id, mentee_id, join_message, learning_goal, status, joined_at, left_at)
                    VALUES (9501, 9301, 9102, 'historic', 'historic goal', 'LEFT', TIMESTAMP '2025-12-01 00:00:00', TIMESTAMP '2026-01-06 00:00:00'),
                           (9502, 9301, 9103, 'current', 'current goal', 'ACTIVE', TIMESTAMP '2026-01-07 00:00:00', NULL)
                    """);
            sql.executeUpdate("""
                    INSERT INTO notifications(notification_id, recipient_id, type, title, message, reference_type,
                        reference_id, event_key, created_at)
                    VALUES (9601, 9102, 'MENTORSHIP_SLOT_JOINED', 'Legacy notice', 'Legacy reference',
                        'MENTORSHIP_SLOT', 9301, 'legacy-mentorship-reference', TIMESTAMP '2026-01-01 08:15:00')
                    """);
        }

        Flyway upgraded = Flyway.configure().dataSource(url, username, password)
                .locations("classpath:db/migration").load();
        assertThat(upgraded.migrate().migrationsExecuted).isEqualTo(1);

        try (Connection connection = DriverManager.getConnection(url, username, password);
             Statement sql = connection.createStatement()) {
            sql.executeUpdate("""
                    INSERT INTO mentorship_enrollments(enrollment_id, slot_id, mentee_id, join_message, learning_goal, status, joined_at, active_marker)
                    VALUES (9503, 9301, 9102, 'rejoined', 'new goal', 'ACTIVE', TIMESTAMP '2026-01-08 00:00:00', TRUE)
                    """);
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_occurrences WHERE slot_id=9301")).isEqualTo(13);
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_occurrences WHERE slot_id=9302")).isEqualTo(11);
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_occurrences WHERE slot_id=9303")).isEqualTo(1);
            assertThat(value(sql, "SELECT meeting_count FROM mentorship_slots WHERE slot_id=9301")).isEqualTo(12);
            assertThat(value(sql, "SELECT current_mentee_count FROM mentorship_slots WHERE slot_id=9301")).isEqualTo(1);
            assertThat(text(sql, "SELECT status FROM mentorship_slots WHERE slot_id=9301")).isEqualTo("OPEN");
            assertThat(bool(sql, "SELECT enrollment_open FROM mentorship_slots WHERE slot_id=9301")).isTrue();
            assertThat(text(sql, "SELECT status FROM mentorship_slots WHERE slot_id=9302")).isEqualTo("CLOSED");
            assertThat(bool(sql, "SELECT enrollment_open FROM mentorship_slots WHERE slot_id=9302")).isFalse();
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_enrollments WHERE slot_id=9301 AND mentee_id=9102")).isEqualTo(2);
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_enrollments WHERE enrollment_id=9501 AND active_marker IS NULL")).isEqualTo(1);
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_enrollments WHERE enrollment_id=9502 AND active_marker=TRUE")).isEqualTo(1);
            assertThat(text(sql, "SELECT join_message FROM mentorship_enrollments WHERE enrollment_id=9501")).isEqualTo("historic");
            assertThat(text(sql, "SELECT learning_goal FROM mentorship_enrollments WHERE enrollment_id=9502")).isEqualTo("current goal");
            assertThat(dateTime(sql, "SELECT starts_at FROM mentorship_occurrences WHERE occurrence_id=9401"))
                    .isEqualTo(LocalDateTime.of(2026, 1, 5, 9, 0));
            assertThat(dateTime(sql, "SELECT ends_at FROM mentorship_occurrences WHERE occurrence_id=9402"))
                    .isEqualTo(LocalDateTime.of(2026, 1, 5, 10, 30));
            assertThat(value(sql, "SELECT COUNT(*) FROM mentorship_occurrences WHERE occurrence_id IN (9401,9402)"))
                    .isEqualTo(2);
            assertThat(value(sql, "SELECT reference_id FROM notifications WHERE notification_id=9601")).isEqualTo(9301);
            assertThat(text(sql, "SELECT event_key FROM notifications WHERE notification_id=9601"))
                    .isEqualTo("legacy-mentorship-reference");
            assertThat(dateTime(sql, "SELECT created_at FROM notifications WHERE notification_id=9601"))
                    .isEqualTo(LocalDateTime.of(2026, 1, 1, 8, 15));
            assertThat(text(sql, "SELECT version FROM flyway_schema_history WHERE success=TRUE ORDER BY installed_rank DESC LIMIT 1")).isEqualTo("26");
        }
    }

    private long value(Statement sql, String query) throws Exception {
        try (ResultSet result = sql.executeQuery(query)) { result.next(); return result.getLong(1); }
    }

    private String text(Statement sql, String query) throws Exception {
        try (ResultSet result = sql.executeQuery(query)) { result.next(); return result.getString(1); }
    }

    private boolean bool(Statement sql, String query) throws Exception {
        try (ResultSet result = sql.executeQuery(query)) { result.next(); return result.getBoolean(1); }
    }

    private LocalDateTime dateTime(Statement sql, String query) throws Exception {
        try (ResultSet result = sql.executeQuery(query)) {
            result.next();
            return result.getTimestamp(1).toLocalDateTime();
        }
    }
}
