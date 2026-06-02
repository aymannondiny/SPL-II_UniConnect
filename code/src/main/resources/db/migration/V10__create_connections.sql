-- ================================================
-- V10: CONNECTIONS MODULE
-- ================================================

-- ================================================
-- CONNECTIONS TABLE
-- ================================================
CREATE TABLE connections (
                             connection_id BIGSERIAL PRIMARY KEY,
                             user_id_1 BIGINT NOT NULL,
                             user_id_2 BIGINT NOT NULL,
                             status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
                                 CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')),  -- ✅ ADDED: REJECTED
                             requested_by BIGINT NOT NULL,
                             request_message TEXT,
                             requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             accepted_at TIMESTAMP,
                             updated_at TIMESTAMP,  -- ✅ ADDED: Track updates

    -- Foreign Keys
                             CONSTRAINT fk_connection_user1 FOREIGN KEY (user_id_1)
                                 REFERENCES users(user_id) ON DELETE CASCADE,
                             CONSTRAINT fk_connection_user2 FOREIGN KEY (user_id_2)
                                 REFERENCES users(user_id) ON DELETE CASCADE,
                             CONSTRAINT fk_connection_requested_by FOREIGN KEY (requested_by)
                                 REFERENCES users(user_id) ON DELETE CASCADE,

    -- Unique: prevent duplicate connections (bidirectional)
    -- user_id_1 is ALWAYS the smaller ID (enforced in service layer)
                             CONSTRAINT uk_connection_users UNIQUE (user_id_1, user_id_2),

    -- Self-connection prevention
                             CONSTRAINT chk_no_self_connection CHECK (user_id_1 <> user_id_2),

    -- Ordering constraint: user_id_1 must always be smaller
    -- This enforces canonical form for bidirectional uniqueness
                             CONSTRAINT chk_user_order CHECK (user_id_1 < user_id_2)
);

-- ================================================
-- INDEXES
-- ================================================

-- Single column indexes
CREATE INDEX idx_connection_user1 ON connections(user_id_1);
CREATE INDEX idx_connection_user2 ON connections(user_id_2);
CREATE INDEX idx_connection_status ON connections(status);
CREATE INDEX idx_connection_requested_by ON connections(requested_by);
CREATE INDEX idx_connection_requested_at ON connections(requested_at DESC);  -- ✅ ADDED: For sorting

-- Compound indexes: optimize common queries
CREATE INDEX idx_connection_user1_status ON connections(user_id_1, status);
CREATE INDEX idx_connection_user2_status ON connections(user_id_2, status);

-- ✅ ADDED: Optimize "pending requests received" query
CREATE INDEX idx_connection_pending_receiver ON connections(user_id_1, user_id_2, status)
    WHERE status = 'PENDING';

-- ================================================
-- TRIGGER: Auto-update updated_at
-- ================================================
-- ✅ ADDED: Automatically set updated_at on row updates
CREATE OR REPLACE FUNCTION update_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_connections_updated_at
    BEFORE UPDATE ON connections
    FOR EACH ROW
    EXECUTE FUNCTION update_connections_updated_at();

-- ================================================
-- COMMENTS
-- ================================================
COMMENT ON TABLE connections IS 'Peer connections between users (students, alumni)';
COMMENT ON COLUMN connections.connection_id IS 'Primary key for connections';
COMMENT ON COLUMN connections.user_id_1 IS 'Always the smaller user_id (canonical form)';
COMMENT ON COLUMN connections.user_id_2 IS 'Always the larger user_id (canonical form)';
COMMENT ON COLUMN connections.requested_by IS 'Who sent the connection request';
COMMENT ON COLUMN connections.status IS 'PENDING = awaiting response, ACCEPTED = connected, REJECTED = declined';
COMMENT ON COLUMN connections.request_message IS 'Optional message sent with connection request';
COMMENT ON COLUMN connections.requested_at IS 'When the connection request was sent';
COMMENT ON COLUMN connections.accepted_at IS 'When the connection was accepted (NULL if still pending/rejected)';
COMMENT ON COLUMN connections.updated_at IS 'Last update timestamp';
COMMENT ON CONSTRAINT chk_user_order ON connections IS
    'Enforces canonical ordering to prevent (A,B) and (B,A) duplicates';