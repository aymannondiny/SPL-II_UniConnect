-- ================================================
-- V8: EVENTS & ANNOUNCEMENTS MODULE
-- ================================================

-- ================================================
-- 1. EVENTS TABLE
-- ================================================
CREATE TABLE events (
                        event_id BIGSERIAL PRIMARY KEY,
                        creator_id BIGINT NOT NULL,
                        title VARCHAR(255) NOT NULL,
                        category VARCHAR(50) NOT NULL CHECK (category IN ('ACADEMIC', 'CULTURAL', 'SPORTS', 'TECH', 'WORKSHOP', 'SOCIAL', 'OTHER')),
                        description TEXT NOT NULL,
                        event_date DATE NOT NULL,
                        event_time TIME NOT NULL,
                        location VARCHAR(255) NOT NULL,
                        meeting_link VARCHAR(500),
                        max_attendees INTEGER CHECK (max_attendees > 0),
                        rsvp_required BOOLEAN NOT NULL DEFAULT FALSE,
                        poster_image VARCHAR(500),
                        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                        CONSTRAINT fk_event_creator FOREIGN KEY (creator_id)
                            REFERENCES users(user_id) ON DELETE CASCADE
);

-- Indexes for events
CREATE INDEX idx_event_creator ON events(creator_id);
CREATE INDEX idx_event_category ON events(category);
CREATE INDEX idx_event_date ON events(event_date);

-- ================================================
-- 2. EVENT RSVPS TABLE
-- ================================================
CREATE TABLE event_rsvps (
                             rsvp_id BIGSERIAL PRIMARY KEY,
                             event_id BIGINT NOT NULL,
                             user_id BIGINT NOT NULL,
                             status VARCHAR(20) NOT NULL CHECK (status IN ('GOING', 'INTERESTED', 'NOT_GOING')),
                             created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                             CONSTRAINT fk_rsvp_event FOREIGN KEY (event_id)
                                 REFERENCES events(event_id) ON DELETE CASCADE,
                             CONSTRAINT fk_rsvp_user FOREIGN KEY (user_id)
                                 REFERENCES users(user_id) ON DELETE CASCADE,
                             CONSTRAINT uk_event_rsvp_user UNIQUE (event_id, user_id)
);

-- Indexes for event_rsvps
CREATE INDEX idx_rsvp_event ON event_rsvps(event_id);
CREATE INDEX idx_rsvp_user ON event_rsvps(user_id);
CREATE INDEX idx_rsvp_status ON event_rsvps(status);

-- ================================================
-- 3. ANNOUNCEMENTS TABLE
-- ================================================
CREATE TABLE announcements (
                               announcement_id BIGSERIAL PRIMARY KEY,
                               creator_id BIGINT NOT NULL,
                               title VARCHAR(255) NOT NULL,
                               content TEXT NOT NULL,
                               priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL' CHECK (priority IN ('NORMAL', 'IMPORTANT', 'URGENT')),
                               target_audience VARCHAR(100),
                               expiry_date DATE,
                               created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

                               CONSTRAINT fk_announcement_creator FOREIGN KEY (creator_id)
                                   REFERENCES users(user_id) ON DELETE CASCADE
);

-- Indexes for announcements
CREATE INDEX idx_announcement_creator ON announcements(creator_id);
CREATE INDEX idx_announcement_priority ON announcements(priority);
CREATE INDEX idx_announcement_created ON announcements(created_at);

-- ================================================
-- 4. COMMENTS (Optional for version tracking)
-- ================================================
COMMENT ON TABLE events IS 'Events created by users (clubs, students, alumni)';
COMMENT ON TABLE event_rsvps IS 'User responses to events';
COMMENT ON TABLE announcements IS 'Important announcements from clubs/admins';

COMMENT ON COLUMN events.category IS 'Event type: ACADEMIC, CULTURAL, SPORTS, TECH, WORKSHOP, SOCIAL, OTHER';
COMMENT ON COLUMN events.rsvp_required IS 'Whether users must RSVP to attend';
COMMENT ON COLUMN event_rsvps.status IS 'GOING, INTERESTED, NOT_GOING';
COMMENT ON COLUMN announcements.priority IS 'NORMAL, IMPORTANT, URGENT';
COMMENT ON COLUMN announcements.target_audience IS 'E.g., "All", "CSE Department", "Tech Clubs"';