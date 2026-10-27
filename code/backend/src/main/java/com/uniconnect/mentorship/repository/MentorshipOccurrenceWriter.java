package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorshipOccurrence;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.Timestamp;
import java.util.List;

/** Uses the surrounding JPA transaction, avoiding one IDENTITY insert round trip per meeting. */
@Repository
public class MentorshipOccurrenceWriter {
    private final JdbcTemplate jdbc;

    public MentorshipOccurrenceWriter(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    public void insertAll(List<MentorshipOccurrence> meetings) {
        if (meetings.isEmpty()) return;
        jdbc.batchUpdate("""
                insert into mentorship_occurrences (slot_id, starts_at, ends_at)
                values (?, ?, ?)
                """, meetings, 52, (statement, meeting) -> {
            statement.setLong(1, meeting.getSlot().getId());
            statement.setTimestamp(2, Timestamp.valueOf(meeting.getStartsAt()));
            statement.setTimestamp(3, Timestamp.valueOf(meeting.getEndsAt()));
        });
    }
}
