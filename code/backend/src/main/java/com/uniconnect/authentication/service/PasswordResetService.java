package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.PasswordResetToken;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.PasswordResetTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.Locale;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PasswordResetService {
    private final UserRepository users;
    private final PasswordResetTokenRepository tokens;
    private final AuthenticationTokenGenerator generator;
    private final PasswordResetEmailSender sender;
    private final PasswordEncoder passwords;
    private final SessionService sessions;
    private final Clock clock;

    public PasswordResetService(UserRepository users, PasswordResetTokenRepository tokens,
            AuthenticationTokenGenerator generator, PasswordResetEmailSender sender,
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
        users.findForUpdateByEmail(email.strip().toLowerCase(Locale.ROOT))
                .filter(User::canResetPassword).ifPresent(user -> {
                    LocalDateTime now = now();
                    revokeOutstanding(user.getUserId(), now);
                    String raw = generator.generate();
                    tokens.saveAndFlush(new PasswordResetToken(user, generator.hash(raw), now));
                    sender.send(user.getEmail(), raw);
                });
    }

    @Transactional
    public void reset(String rawToken, String newPassword) {
        if (newPassword == null || newPassword.isBlank() || newPassword.length() < 8
                || newPassword.length() > 72 || newPassword.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new BadRequestException("INVALID_PASSWORD", "Password must contain 8–72 characters and at most 72 UTF-8 bytes.");
        }
        if (!generator.isWellFormed(rawToken)) throw invalidToken();
        String hash = generator.hash(rawToken);
        // Resolve only the owner before locking; token state must be loaded after the user lock.
        Long owner = tokens.findOwnerIdByTokenHash(hash).orElseThrow(this::invalidToken);
        User user = users.findForUpdateById(owner).orElseThrow(this::invalidToken);
        PasswordResetToken token = tokens.findByTokenHash(hash).orElseThrow(this::invalidToken);
        LocalDateTime now = now();
        if (!user.canResetPassword() || !token.isUsable(now)) throw invalidToken();
        user.resetPassword(passwords.encode(newPassword), now);
        token.markUsed(now);
        revokeOutstanding(owner, now);
        sessions.revokeAllForAccount(owner);
    }

    private void revokeOutstanding(Long owner, LocalDateTime now) {
        tokens.findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(owner).forEach(token -> token.revoke(now));
    }

    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }

    private BadRequestException invalidToken() {
        return new BadRequestException("INVALID_PASSWORD_RESET_TOKEN", "Password reset link is invalid or no longer usable.");
    }
}
