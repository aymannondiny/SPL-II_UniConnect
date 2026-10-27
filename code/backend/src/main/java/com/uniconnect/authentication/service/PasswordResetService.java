package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.PasswordResetToken;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.PasswordResetTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Locale;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {
    private static final int MAX_ISSUANCES_PER_HOUR = 5;
    private static final int RESEND_COOLDOWN_SECONDS = 60;

    private final UserRepository users;
    private final PasswordResetTokenRepository tokens;
    private final VerificationCodeGenerator generator;
    private final PasswordResetEmailSender sender;
    private final PasswordEncoder passwords;
    private final SessionService sessions;
    private final Clock clock;

    public PasswordResetService(UserRepository users, PasswordResetTokenRepository tokens,
            VerificationCodeGenerator generator, PasswordResetEmailSender sender,
            PasswordEncoder passwords, SessionService sessions, Clock clock) {
        this.users = users;
        this.tokens = tokens;
        this.generator = generator;
        this.sender = sender;
        this.passwords = passwords;
        this.sessions = sessions;
        this.clock = clock;
    }

    @Transactional
    public void requestReset(String email) {
        users.findForUpdateByEmail(normalize(email))
                .filter(User::canResetPassword)
                .ifPresent(user -> issue(user, now()));
    }

    private void issue(User user, LocalDateTime now) {
        PasswordResetToken previous = tokens
                .findFirstByUserUserIdOrderByCreatedAtDescTokenIdDesc(user.getUserId()).orElse(null);
        if (previous != null && previous.getCreatedAt().plusSeconds(RESEND_COOLDOWN_SECONDS).isAfter(now)) return;
        if (tokens.countByUserUserIdAndCreatedAtAfter(user.getUserId(), now.minusHours(1))
                >= MAX_ISSUANCES_PER_HOUR) return;
        String code = nextCode(user, previous);
        String salt = generator.generateSalt();
        String digest = generator.digest(user.getUserId(), user.getEmail(), salt, code);
        revokeOutstanding(user.getUserId(), now);
        tokens.saveAndFlush(new PasswordResetToken(user, digest, salt, now));
        sender.send(user.getEmail(), code);
    }

    private String nextCode(User user, PasswordResetToken previous) {
        String code;
        do {
            code = generator.generateCode();
        } while (previous != null && previous.getCodeSalt() != null
                && generator.matches(user.getUserId(), user.getEmail(), previous.getCodeSalt(),
                        previous.getTokenHash(), code));
        return code;
    }

    @Transactional(noRollbackFor = BadRequestException.class)
    public void verifyCode(String email, String code) {
        User user = lockAccount(email);
        validateCode(user, code);
    }

    @Transactional(noRollbackFor = BadRequestException.class)
    public void reset(String email, String code, String newPassword) {
        PasswordPolicy.validate(newPassword);
        User user = lockAccount(email);
        PasswordResetToken challenge = validateCode(user, code);
        LocalDateTime now = now();
        user.resetPassword(passwords.encode(newPassword), now);
        challenge.markUsed(now);
        revokeOutstanding(user.getUserId(), now);
        sessions.revokeAllForAccount(user.getUserId());
    }

    private User lockAccount(String email) {
        return users.findForUpdateByEmail(normalize(email)).orElseThrow(this::invalidCode);
    }

    private PasswordResetToken validateCode(User user, String code) {
        if (code == null || !code.matches("[0-9]{6}")) throw invalidCode();
        PasswordResetToken challenge = tokens
                .findFirstByUserUserIdAndUsedAtIsNullAndRevokedAtIsNullOrderByCreatedAtDescTokenIdDesc(user.getUserId())
                .orElseThrow(this::invalidCode);
        LocalDateTime now = now();
        if (!user.canResetPassword() || !challenge.isUsable(now)) throw invalidCode();
        if (!generator.matches(user.getUserId(), user.getEmail(), challenge.getCodeSalt(),
                challenge.getTokenHash(), code)) {
            challenge.recordFailedAttempt(now);
            tokens.saveAndFlush(challenge);
            throw invalidCode();
        }
        return challenge;
    }

    private void revokeOutstanding(Long owner, LocalDateTime now) {
        tokens.findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(owner)
                .forEach(token -> token.revoke(now));
    }

    private String normalize(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }

    private LocalDateTime now() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }

    private BadRequestException invalidCode() {
        return new BadRequestException("INVALID_PASSWORD_RESET_CODE",
                "Password reset code is invalid or no longer usable.");
    }
}
