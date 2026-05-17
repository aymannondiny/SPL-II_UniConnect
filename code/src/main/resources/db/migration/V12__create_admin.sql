-- ================================================
-- V12: ADMIN & MODERATION MODULE (FINAL MIGRATION)
-- ================================================

-- ================================================
-- 1. CONTENT REPORTS TABLE
-- ================================================
CREATE TABLE content_reports (
                                 report_id BIGSERIAL PRIMARY KEY,
                                 reported_by BIGINT NOT NULL,
                                 content_type VARCHAR(50) NOT NULL CHECK (content_type IN (
                                                                                           'USER', 'PROJECT', 'EVENT', 'MESSAGE', 'JOB', 'ANNOUNCEMENT'
                                     )),
                                 content_id BIGINT NOT NULL,
                                 reason TEXT NOT NULL,
                                 status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN (
                                                                                                 'PENDING', 'UNDER_REVIEW', 'RESOLVED', 'DISMISSED'
                                     )),
                                 admin_notes TEXT,
                                 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 reviewed_at TIMESTAMP,
                                 reviewed_by BIGINT,

    -- Foreign Keys
                                 CONSTRAINT fk_report_reported_by FOREIGN KEY (reported_by)
                                     REFERENCES users(user_id) ON DELETE CASCADE,
                                 CONSTRAINT fk_report_reviewed_by FOREIGN KEY (reviewed_by)
                                     REFERENCES users(user_id) ON DELETE SET NULL
);

-- Indexes for content_reports
CREATE INDEX idx_report_reported_by ON content_reports(reported_by);
CREATE INDEX idx_report_status ON content_reports(status);
CREATE INDEX idx_report_content_type ON content_reports(content_type);
CREATE INDEX idx_report_created ON content_reports(created_at);

-- Compound: fast lookup "show all reports for project #5"
CREATE INDEX idx_report_content_type_id ON content_reports(content_type, content_id);

-- ================================================
-- 2. MODERATION ACTIONS TABLE
-- ================================================
CREATE TABLE moderation_actions (
                                    action_id BIGSERIAL PRIMARY KEY,
                                    admin_id BIGINT NOT NULL,
                                    action_type VARCHAR(50) NOT NULL CHECK (action_type IN (
                                                                                            'WARN', 'SUSPEND', 'BAN', 'DELETE_CONTENT'
                                        )),
                                    target_user_id BIGINT,
                                    target_content_type VARCHAR(50) CHECK (target_content_type IN (
                                                                                                   'USER', 'PROJECT', 'EVENT', 'MESSAGE', 'JOB', 'ANNOUNCEMENT'
                                        )),
                                    target_content_id BIGINT,
                                    reason TEXT NOT NULL,
                                    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Foreign Keys
                                    CONSTRAINT fk_mod_action_admin FOREIGN KEY (admin_id)
                                        REFERENCES users(user_id) ON DELETE CASCADE,
                                    CONSTRAINT fk_mod_action_target_user FOREIGN KEY (target_user_id)
                                        REFERENCES users(user_id) ON DELETE SET NULL,

    -- At least one target must be provided
                                    CONSTRAINT chk_mod_action_target CHECK (
                                        target_user_id IS NOT NULL OR
                                        (target_content_type IS NOT NULL AND target_content_id IS NOT NULL)
                                        )
);

-- Indexes for moderation_actions
CREATE INDEX idx_mod_action_admin ON moderation_actions(admin_id);
CREATE INDEX idx_mod_action_target_user ON moderation_actions(target_user_id);
CREATE INDEX idx_mod_action_type ON moderation_actions(action_type);
CREATE INDEX idx_mod_action_created ON moderation_actions(created_at);

-- ================================================
-- 3. COMMENTS
-- ================================================
COMMENT ON TABLE content_reports IS 'Reports submitted by users about inappropriate content';
COMMENT ON TABLE moderation_actions IS 'Actions taken by admins against users or content';

COMMENT ON COLUMN content_reports.content_type IS 'Type of reported content: USER, PROJECT, EVENT, MESSAGE, JOB, ANNOUNCEMENT';
COMMENT ON COLUMN content_reports.content_id IS 'ID of the reported content';
COMMENT ON COLUMN content_reports.admin_notes IS 'Internal notes by reviewers - NOT visible to reporter';
COMMENT ON COLUMN content_reports.status IS 'PENDING → UNDER_REVIEW → RESOLVED or DISMISSED';

COMMENT ON COLUMN moderation_actions.action_type IS 'WARN, SUSPEND, BAN, DELETE_CONTENT';
COMMENT ON COLUMN moderation_actions.target_content_type IS 'Type of moderated content (optional)';
COMMENT ON CONSTRAINT chk_mod_action_target ON moderation_actions IS
    'At least one target (user or content) must be specified';