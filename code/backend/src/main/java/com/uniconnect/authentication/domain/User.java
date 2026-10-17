package com.uniconnect.authentication.domain;

import com.uniconnect.shared.security.AccountStatus;
import com.uniconnect.shared.security.PlatformRole;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "email", length = 320)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "platform_role", nullable = false, length = 50)
    private PlatformRole platformRole;

    @Enumerated(EnumType.STRING)
    @Column(name = "account_status", nullable = false, length = 50)
    private AccountStatus accountStatus;

    @Column(name = "anonymized_at")
    private LocalDateTime anonymizedAt;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    protected User() {
    }

    User(
            String fullName,
            String email,
            String passwordHash,
            PlatformRole platformRole,
            AccountStatus accountStatus,
            LocalDateTime createdAt,
            LocalDateTime updatedAt
    ) {
        this.fullName = fullName;
        this.email = email;
        this.passwordHash = passwordHash;
        this.platformRole = platformRole;
        this.accountStatus = accountStatus;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static User register(
            String fullName,
            String email,
            String passwordHash,
            PlatformRole platformRole
    ) {
        LocalDateTime now = LocalDateTime.now();

        return new User(
                fullName,
                email,
                passwordHash,
                platformRole,
                AccountStatus.PENDING_VERIFICATION,
                now,
                now
        );
    }

    public void updateFullName(String fullName, LocalDateTime now) {
        if (fullName == null || fullName.isBlank() || fullName.length() > 100) {
            throw new IllegalArgumentException("Full name must contain 1–100 characters");
        }
        this.fullName = fullName;
        this.updatedAt = now;
    }

    public boolean canResetPassword() {
        return !isAnonymized() && email != null && passwordHash != null;
    }

    public void resetPassword(String encodedPassword, LocalDateTime now) {
        if (!canResetPassword()) throw new IllegalStateException("Account credentials are unavailable");
        passwordHash = encodedPassword;
        updatedAt = now;
    }

    public boolean canVerifyEmail() {
        return accountStatus == AccountStatus.PENDING_VERIFICATION && !isAnonymized();
    }

    public void verifyEmail(LocalDateTime now) {
        if (!canVerifyEmail()) {
            throw new IllegalStateException("Account is not pending verification");
        }
        accountStatus = AccountStatus.ACTIVE;
        updatedAt = now;
    }

    public Long getUserId() {
        return userId;
    }

    public String getFullName() {
        return fullName;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public PlatformRole getPlatformRole() {
        return platformRole;
    }

    public AccountStatus getAccountStatus() {
        return accountStatus;
    }

    public LocalDateTime getAnonymizedAt() {
        return anonymizedAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public boolean isAnonymized() {
        return anonymizedAt != null;
    }

    public boolean canAuthenticate() {
        return accountStatus == AccountStatus.ACTIVE
                && !isAnonymized();
    }

    public boolean canPerformProtectedAction() {
        return canAuthenticate();
    }
}
