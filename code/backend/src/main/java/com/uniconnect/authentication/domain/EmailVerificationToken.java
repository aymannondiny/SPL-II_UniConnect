package com.uniconnect.authentication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "email_verification_tokens")
public class EmailVerificationToken {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long tokenId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    private LocalDateTime usedAt;

    private LocalDateTime revokedAt;

    protected EmailVerificationToken() {}

    public EmailVerificationToken(User user, String tokenHash, LocalDateTime now) {
        this.user = user;
        this.tokenHash = tokenHash;
        this.createdAt = now;
        this.expiresAt = now.plusHours(24);
    }

    public Long getUserId() { return user.getUserId(); }

    public String getTokenHash() { return tokenHash; }

    public LocalDateTime getExpiresAt() { return expiresAt; }

    public boolean isUsable(LocalDateTime now) {
        return usedAt == null && revokedAt == null && now.isBefore(expiresAt);
    }

    public void markUsed(LocalDateTime now) { usedAt = now; }

    public void revoke(LocalDateTime now) { revokedAt = now; }
}
