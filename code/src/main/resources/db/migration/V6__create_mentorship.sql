-- ================================================
-- V6: Mentorship Module Tables (NORMALIZED)
-- ================================================

-- Mentors
CREATE TABLE mentors (
                         mentor_id SERIAL PRIMARY KEY,
                         user_id INTEGER UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                         bio TEXT CHECK (LENGTH(bio) <= 5000),
                         mentoring_approach TEXT NOT NULL CHECK (LENGTH(mentoring_approach) >= 10),
                         status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (status IN ('Available', 'Unavailable')),
                         created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mentors_user ON mentors(user_id);
CREATE INDEX idx_mentors_status ON mentors(status);

-- Mentor Expertise
CREATE TABLE mentor_expertise (
                                  expertise_id SERIAL PRIMARY KEY,
                                  mentor_id INTEGER NOT NULL REFERENCES mentors(mentor_id) ON DELETE CASCADE,
                                  topic VARCHAR(100) NOT NULL CHECK (LENGTH(topic) >= 2),
                                  description TEXT CHECK (LENGTH(description) <= 1000)
);

CREATE INDEX idx_mentor_expertise_mentor ON mentor_expertise(mentor_id);
CREATE INDEX idx_mentor_expertise_topic ON mentor_expertise(topic);

-- Mentorship Slots (NO day_of_week here - moved to slot_schedules)
CREATE TABLE mentorship_slots (
                                  slot_id SERIAL PRIMARY KEY,
                                  mentor_id INTEGER NOT NULL REFERENCES mentors(mentor_id) ON DELETE CASCADE,
                                  title VARCHAR(200) NOT NULL CHECK (LENGTH(title) >= 5),
                                  description TEXT NOT NULL CHECK (LENGTH(description) >= 10),
                                  start_time TIME NOT NULL,
                                  end_time TIME NOT NULL,
                                  recurrence VARCHAR(20) NOT NULL CHECK (recurrence IN ('Weekly', 'BiWeekly', 'OneTime')),
                                  max_mentees INTEGER NOT NULL CHECK (max_mentees >= 7 AND max_mentees <= 10),
                                  current_mentees INTEGER NOT NULL DEFAULT 0 CHECK (current_mentees >= 0),
                                  location VARCHAR(255) NOT NULL CHECK (LENGTH(location) >= 3),
                                  meeting_link VARCHAR(500),
                                  start_date DATE NOT NULL,
                                  end_date DATE,
                                  status VARCHAR(20) NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Full', 'Closed')),
                                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                  CONSTRAINT valid_time_range CHECK (end_time > start_time),
                                  CONSTRAINT valid_date_range CHECK (end_date IS NULL OR end_date > start_date)
);

CREATE INDEX idx_mentorship_slots_mentor ON mentorship_slots(mentor_id);
CREATE INDEX idx_mentorship_slots_status ON mentorship_slots(status);

-- Slot Schedules (Junction Table - handles multiple days per slot)
CREATE TABLE slot_schedules (
                                schedule_id SERIAL PRIMARY KEY,
                                slot_id INTEGER NOT NULL REFERENCES mentorship_slots(slot_id) ON DELETE CASCADE,
                                day_of_week VARCHAR(10) NOT NULL CHECK (day_of_week IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
                                UNIQUE(slot_id, day_of_week)
);

CREATE INDEX idx_slot_schedules_slot ON slot_schedules(slot_id);
CREATE INDEX idx_slot_schedules_day ON slot_schedules(day_of_week);

-- Mentorship Enrollments
CREATE TABLE mentorship_enrollments (
                                        enrollment_id SERIAL PRIMARY KEY,
                                        slot_id INTEGER NOT NULL REFERENCES mentorship_slots(slot_id) ON DELETE CASCADE,
                                        mentee_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                        message TEXT,
                                        learning_goals TEXT CHECK (LENGTH(learning_goals) <= 1000),
                                        enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                        left_at TIMESTAMP,
                                        UNIQUE(slot_id, mentee_id)
);

CREATE INDEX idx_mentorship_enrollments_slot ON mentorship_enrollments(slot_id);
CREATE INDEX idx_mentorship_enrollments_mentee ON mentorship_enrollments(mentee_id);