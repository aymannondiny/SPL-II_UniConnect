ALTER TABLE password_reset_tokens ADD COLUMN code_salt VARCHAR(43);
ALTER TABLE password_reset_tokens ADD COLUMN failed_attempts INTEGER NOT NULL DEFAULT 0;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_attempts_valid CHECK (failed_attempts BETWEEN 0 AND 5);
UPDATE password_reset_tokens SET revoked_at = CURRENT_TIMESTAMP WHERE used_at IS NULL AND revoked_at IS NULL;
CREATE INDEX idx_password_reset_issuance ON password_reset_tokens(user_id, created_at);
