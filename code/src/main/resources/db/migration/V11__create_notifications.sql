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
                                   -- Connection notifications
                                                                         'CONNECTION_REQUEST',
                                                                         'CONNECTION_ACCEPTED',

                                   -- Project notifications
                                                                         'PROJECT_APPLICATION',
                                                                         'PROJECT_APPLICATION_ACCEPTED',
                                                                         'PROJECT_APPLICATION_REJECTED',

                                   -- Mentorship notifications
                                                                         'MENTORSHIP_ENROLLMENT',
                                                                         'MENTORSHIP_SLOT_FULL',
                                                                         'MENTORSHIP_SLOT_CLOSED',

                                   -- Chat notifications
                                                                         'NEW_MESSAGE',

                                   -- Event notifications
                                                                         'EVENT_REMINDER',
                                                                         'EVENT_CANCELLED',

                                   -- Career notifications
                                                                         'NEW_JOB_POSTING',

                                   -- Announcement notifications
                                                                         'NEW_ANNOUNCEMENT',

                                   -- Admin notifications
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

-- ================================================
-- INDEXES
-- ================================================

-- Single column indexes
CREATE INDEX idx_notification_user ON notifications(user_id);
CREATE INDEX idx_notification_is_read ON notifications(is_read);
CREATE INDEX idx_notification_created ON notifications(created_at DESC);  -- DESC for sorting
CREATE INDEX idx_notification_type ON notifications(type);

-- Compound index: most common query = "get unread notifications for user"
CREATE INDEX idx_notification_user_read ON notifications(user_id, is_read);

-- ✅ ADDED: Optimize "unread count" query
CREATE INDEX idx_notification_user_unread ON notifications(user_id)
    WHERE is_read = FALSE;

-- ================================================
-- COMMENTS
-- ================================================
COMMENT ON TABLE notifications IS 'In-app notifications for all user actions';
COMMENT ON COLUMN notifications.notification_id IS 'Primary key for notifications';
COMMENT ON COLUMN notifications.user_id IS 'The user who RECEIVES this notification';
COMMENT ON COLUMN notifications.type IS 'Notification category/type';
COMMENT ON COLUMN notifications.content IS 'Notification message displayed to user';
COMMENT ON COLUMN notifications.reference_id IS 'ID of the related entity (project, event, user, etc.)';
COMMENT ON COLUMN notifications.reference_type IS 'Type of related entity: USER, PROJECT, EVENT, MESSAGE, etc.';
COMMENT ON COLUMN notifications.is_read IS 'Whether user has seen/read this notification';
COMMENT ON COLUMN notifications.created_at IS 'When the notification was created';