-- ================================================
-- V11: NOTIFICATIONS MODULE
-- ================================================

-- ================================================
-- NOTIFICATIONS TABLE
-- ================================================
CREATE TABLE notifications (
                               notification_id BIGSERIAL PRIMARY KEY,
                               user_id BIGINT NOT NULL,
                               type VARCHAR(50) NOT NULL CHECK (type IN (
                                                                         'CONNECTION_REQUEST',
                                                                         'CONNECTION_ACCEPTED',
                                                                         'PROJECT_APPLICATION',
                                                                         'PROJECT_APPLICATION_ACCEPTED',
                                                                         'PROJECT_APPLICATION_REJECTED',
                                                                         'MENTORSHIP_ENROLLMENT',
                                                                         'MENTORSHIP_SLOT_FULL',
                                                                         'MENTORSHIP_SLOT_CLOSED',
                                                                         'NEW_MESSAGE',
                                                                         'EVENT_REMINDER',
                                                                         'EVENT_CANCELLED',
                                                                         'NEW_JOB_POSTING',
                                                                         'NEW_ANNOUNCEMENT',
                                                                         'ACCOUNT_WARNING',
                                                                         'ACCOUNT_SUSPENDED',
                                                                         'CONTENT_REMOVED'
                                   )),
                               content TEXT NOT NULL,
                               reference_id BIGINT,
                               reference_type VARCHAR(50),
                               is_read BOOLEAN NOT NULL DEFAULT FALSE,
                               created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
                               CONSTRAINT fk_notification_user FOREIGN KEY (user_id)
                                   REFERENCES users(user_id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_notification_user ON notifications(user_id);
CREATE INDEX idx_notification_is_read ON notifications(is_read);
CREATE INDEX idx_notification_created ON notifications(created_at);
CREATE INDEX idx_notification_type ON notifications(type);

-- Compound: most common query = "get unread notifications for user"
CREATE INDEX idx_notification_user_read ON notifications(user_id, is_read);

-- ================================================
-- COMMENTS
-- ================================================
COMMENT ON TABLE notifications IS 'In-app notifications for all user actions';
COMMENT ON COLUMN notifications.user_id IS 'The user who RECEIVES this notification';
COMMENT ON COLUMN notifications.type IS 'Notification category/type';
COMMENT ON COLUMN notifications.reference_id IS 'ID of the related entity (project, event, etc.)';
COMMENT ON COLUMN notifications.reference_type IS 'Type of related entity: project, event, message, etc.';
COMMENT ON COLUMN notifications.is_read IS 'Whether user has seen this notification';