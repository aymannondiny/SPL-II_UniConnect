package com.uniconnect.authentication.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "password_reset_tokens")
public class PasswordResetToken {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long tokenId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(length = 43)
    private String codeSalt;

    @Column(nullable = false)
    private int failedAttempts;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    private LocalDateTime usedAt;

    private LocalDateTime revokedAt;

    protected PasswordResetToken() {}

    public PasswordResetToken(User user, String tokenHash, String codeSalt, LocalDateTime now) {
        this.user = user;
        this.tokenHash = tokenHash;
        this.codeSalt = codeSalt;
        this.createdAt = now;
        this.expiresAt = now.plusMinutes(10);
    }

    public Long getUserId() { return user.getUserId(); }

    public String getTokenHash() { return tokenHash; }

    public String getCodeSalt() { return codeSalt; }

    public LocalDateTime getCreatedAt() { return createdAt; }

    public int getFailedAttempts() { return failedAttempts; }

    public LocalDateTime getExpiresAt() { return expiresAt; }

    public boolean isUsable(LocalDateTime now) {
        return codeSalt != null && usedAt == null && revokedAt == null && now.isBefore(expiresAt);
    }

    public void markUsed(LocalDateTime now) { usedAt = now; }

    public void revoke(LocalDateTime now) { revokedAt = now; }

    public void recordFailedAttempt(LocalDateTime now) {
        if (failedAttempts >= 5) return;
        failedAttempts++;
        if (failedAttempts == 5) revoke(now);
    }
}
