package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

public class V26__correct_mentorship_lifecycle extends BaseJavaMigration {
    private record Slot(long id, String type, LocalDate start, LocalTime startTime,
                        LocalTime endTime, LocalDate recurrenceEnd, int meetingCount) {}

    @Override public void migrate(Context context) throws Exception {
        Connection c = context.getConnection();
        exec(c, "ALTER TABLE mentorship_slots ADD COLUMN meeting_count INTEGER");
        exec(c, "ALTER TABLE mentorship_slots ADD COLUMN enrollment_open BOOLEAN DEFAULT TRUE NOT NULL");
        exec(c, "ALTER TABLE mentorship_enrollments ADD COLUMN active_marker BOOLEAN");
        exec(c, "UPDATE mentorship_enrollments SET active_marker = TRUE WHERE status = 'ACTIVE'");
        exec(c, "UPDATE mentorship_slots SET enrollment_open = FALSE WHERE status IN ('CLOSED', 'CANCELLED')");
        exec(c, "UPDATE mentorship_slots SET status = 'OPEN' WHERE status = 'FULL'");

        dropSlotMenteeUnique(c);
        exec(c, "ALTER TABLE mentorship_enrollments ADD CONSTRAINT uq_mentorship_active_enrollment UNIQUE (slot_id, mentee_id, active_marker)");
        List<Slot> slots = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT slot_id, schedule_type, start_date, start_time, end_time, recurrence_end_date
                FROM mentorship_slots ORDER BY slot_id
                """); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String type = rs.getString(2);
                LocalDate start = rs.getObject(3, LocalDate.class);
                LocalDate recurrenceEnd = rs.getObject(6, LocalDate.class);
                int step = "BIWEEKLY".equals(type) ? 2 : 1;
                int count = 1;
                if (!"ONE_TIME".equals(type)) {
                    count = recurrenceEnd == null ? 12 : 0;
                    if (recurrenceEnd != null) {
                        // Preserve the pre-V26 calculator exactly: every legacy recurring row was capped at 12.
                        for (LocalDate d = start; !d.isAfter(recurrenceEnd) && count < 12; d = d.plusWeeks(step)) count++;
                    }
                }
                slots.add(new Slot(rs.getLong(1), type, start, rs.getObject(4, LocalTime.class),
                        rs.getObject(5, LocalTime.class), recurrenceEnd, count));
            }
        }

        try (PreparedStatement update = c.prepareStatement("UPDATE mentorship_slots SET meeting_count=? WHERE slot_id=?");
             PreparedStatement exists = c.prepareStatement("SELECT COUNT(*) FROM mentorship_occurrences WHERE slot_id=? AND starts_at=?");
             PreparedStatement insert = c.prepareStatement("INSERT INTO mentorship_occurrences(slot_id, starts_at, ends_at) VALUES (?,?,?)")) {
            for (Slot s : slots) {
                update.setInt(1, s.meetingCount()); update.setLong(2, s.id()); update.addBatch();
                int step = "BIWEEKLY".equals(s.type()) ? 2 : 1;
                for (int i = 0; i < s.meetingCount(); i++) {
                    LocalDate date = s.start().plusWeeks((long) i * step);
                    LocalDateTime startsAt = LocalDateTime.of(date, s.startTime());
                    exists.setLong(1, s.id()); exists.setObject(2, startsAt);
                    try (ResultSet rs = exists.executeQuery()) { rs.next(); if (rs.getLong(1) > 0) continue; }
                    insert.setLong(1, s.id());
                    insert.setObject(2, startsAt);
                    insert.setObject(3, LocalDateTime.of(date, s.endTime()));
                    insert.addBatch();
                }
            }
            update.executeBatch(); insert.executeBatch();
        }
        exec(c, "ALTER TABLE mentorship_slots ALTER COLUMN meeting_count SET NOT NULL");
        exec(c, "ALTER TABLE mentorship_slots ADD CONSTRAINT valid_meeting_count CHECK (meeting_count BETWEEN 1 AND 52)");
        exec(c, "UPDATE mentorship_slots s SET current_mentee_count = (SELECT COUNT(*) FROM mentorship_enrollments e WHERE e.slot_id=s.slot_id AND e.status='ACTIVE')");
    }

    private void dropSlotMenteeUnique(Connection c) throws SQLException {
        List<String> names = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT constraint_name FROM information_schema.table_constraints
                WHERE LOWER(table_name) = 'mentorship_enrollments' AND constraint_type = 'UNIQUE'
                """); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) names.add(rs.getString(1));
        }
        for (String name : names) {
            String quoted = "\"" + name.replace("\"", "\"\"") + "\"";
            try (Statement st = c.createStatement()) { st.execute("ALTER TABLE mentorship_enrollments DROP CONSTRAINT " + quoted); }
        }
    }

    private void exec(Connection c, String sql) throws SQLException {
        try (Statement st = c.createStatement()) { st.execute(sql); }
    }
}
