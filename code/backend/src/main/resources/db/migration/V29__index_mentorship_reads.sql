CREATE INDEX idx_mentorship_occurrences_lifecycle
    ON mentorship_occurrences(slot_id, cancelled_at, ends_at, starts_at);
CREATE INDEX idx_mentorship_enrollments_slot_status
    ON mentorship_enrollments(slot_id, status);
CREATE INDEX idx_mentorship_enrollments_user_status
    ON mentorship_enrollments(mentee_id, status, joined_at);
CREATE INDEX idx_mentorship_slots_listing
    ON mentorship_slots(start_date, start_time, slot_id);
