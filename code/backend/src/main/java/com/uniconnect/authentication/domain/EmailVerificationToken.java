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

    @Column(name = "code_digest", nullable = false, length = 64)
    private String codeDigest;

    @Column(name = "code_salt", nullable = false, length = 43)
    private String codeSalt;

    @Column(name = "failed_attempts", nullable = false)
    private int failedAttempts;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime expiresAt;

    private LocalDateTime usedAt;

    private LocalDateTime revokedAt;

    protected EmailVerificationToken() {}

    public EmailVerificationToken(User user, String codeDigest, String codeSalt, LocalDateTime now) {
        this.user = user;
        this.codeDigest = codeDigest;
        this.codeSalt = codeSalt;
        this.createdAt = now;
        this.expiresAt = now.plusMinutes(10);
    }

    public Long getUserId() { return user.getUserId(); }

    public String getCodeDigest() { return codeDigest; }

    public String getCodeSalt() { return codeSalt; }

    public LocalDateTime getCreatedAt() { return createdAt; }

    public LocalDateTime getExpiresAt() { return expiresAt; }

    public int getFailedAttempts() { return failedAttempts; }

    public boolean isUsable(LocalDateTime now) {
        return usedAt == null && revokedAt == null && now.isBefore(expiresAt);
    }

    public void markUsed(LocalDateTime now) { usedAt = now; }

    public void revoke(LocalDateTime now) { revokedAt = now; }

    public void recordFailedAttempt(LocalDateTime now) {
        if (failedAttempts >= 5) return;
        failedAttempts++;
        if (failedAttempts == 5) revoke(now);
    }
}
