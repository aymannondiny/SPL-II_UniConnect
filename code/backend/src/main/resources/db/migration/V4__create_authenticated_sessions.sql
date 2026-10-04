CREATE TABLE authenticated_sessions (
    session_id UUID PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    access_token_hash VARCHAR(64) NOT NULL UNIQUE,
    refresh_token_hash VARCHAR(64) NOT NULL UNIQUE,
    issued_at TIMESTAMP NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    access_expires_at TIMESTAMP NOT NULL,
    last_seen_at TIMESTAMP,
    revoked_at TIMESTAMP,
    revocation_reason VARCHAR(50),
    CONSTRAINT session_expiry_valid CHECK (expires_at > issued_at),
    CONSTRAINT session_access_expiry_valid CHECK (access_expires_at <= expires_at),
    CONSTRAINT session_revocation_valid CHECK (
        (revoked_at IS NULL AND revocation_reason IS NULL) OR
        (revoked_at IS NOT NULL AND revocation_reason IS NOT NULL))
);
CREATE INDEX idx_authenticated_sessions_user ON authenticated_sessions(user_id);
