-- ================================================
-- V13: FIX NOTIFICATIONS - Add CONNECTION_REJECTED
-- ================================================

-- Drop old constraint
ALTER TABLE notifications
DROP CONSTRAINT notifications_type_check;

-- Add new constraint with CONNECTION_REJECTED
ALTER TABLE notifications
    ADD CONSTRAINT notifications_type_check CHECK (type IN (
                                                            'CONNECTION_REQUEST',
                                                            'CONNECTION_ACCEPTED',
                                                            'CONNECTION_REJECTED',
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
        ));