package com.uniconnect.authentication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "authenticated_sessions")
public class AuthenticatedSession {
    @Id
    @Column(name = "session_id")
    private UUID sessionId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(name = "access_token_hash", nullable = false, unique = true, length = 64)
    private String accessTokenHash;
    @Column(name = "refresh_token_hash", nullable = false, unique = true, length = 64)
    private String refreshTokenHash;
    @Column(name = "issued_at", nullable = false)
    private LocalDateTime issuedAt;
    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;
    @Column(name = "access_expires_at", nullable = false)
    private LocalDateTime accessExpiresAt;
    @Column(name = "last_seen_at")
    private LocalDateTime lastSeenAt;
    @Column(name = "revoked_at")
    private LocalDateTime revokedAt;
    @Column(name = "revocation_reason", length = 50)
    private String revocationReason;

    protected AuthenticatedSession() { }

    public AuthenticatedSession(User user, String accessHash, String refreshHash,
            LocalDateTime now, LocalDateTime expiresAt, LocalDateTime accessExpiresAt) {
        this.sessionId = UUID.randomUUID();
        this.user = user;
        this.issuedAt = now;
        this.expiresAt = expiresAt;
        rotate(accessHash, refreshHash, now, accessExpiresAt);
    }

    public boolean isValid(LocalDateTime now) {
        return revokedAt == null && now.isBefore(expiresAt) && user.canAuthenticate();
    }

    public boolean allowsAccess(LocalDateTime now) {
        return isValid(now) && now.isBefore(accessExpiresAt);
    }

    public void rotate(String accessHash, String refreshHash, LocalDateTime now, LocalDateTime accessExpiry) {
        this.accessTokenHash = accessHash;
        this.refreshTokenHash = refreshHash;
        this.accessExpiresAt = accessExpiry.isBefore(expiresAt) ? accessExpiry : expiresAt;
        this.lastSeenAt = now;
    }

    public void revoke(LocalDateTime now, String reason) {
        if (revokedAt == null) {
            revokedAt = now;
            revocationReason = reason;
        }
    }

    public UUID getSessionId() { return sessionId; }
    public User getUser() { return user; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public LocalDateTime getAccessExpiresAt() { return accessExpiresAt; }
}
