package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.EmailVerificationToken;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.EmailVerificationTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmailVerificationService {
    private final UserRepository users;
    private final EmailVerificationTokenRepository tokens;
    private final VerificationTokenGenerator generator;
    private final VerificationEmailSender sender;
    private final Clock clock;

    public EmailVerificationService(UserRepository users, EmailVerificationTokenRepository tokens,
            VerificationTokenGenerator generator, VerificationEmailSender sender, Clock clock) {
        this.users = users;
        this.tokens = tokens;
        this.generator = generator;
        this.sender = sender;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void issueForRegistration(User user) {
        issue(user);
    }

    @Transactional
    public void resend(String email) {
        users.findForUpdateByEmail(email.trim().toLowerCase(Locale.ROOT))
                .filter(User::canVerifyEmail).ifPresent(this::issue);
    }

    private void issue(User user) {
        LocalDateTime now = LocalDateTime.now(clock);
        tokens.findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(user.getUserId())
                .forEach(token -> token.revoke(now));
        String rawToken = generator.generate();
        tokens.saveAndFlush(new EmailVerificationToken(user, generator.hash(rawToken), now));
        sender.send(user.getEmail(), rawToken);
    }

    @Transactional
    public void verify(String rawToken) {
        if (rawToken == null || !rawToken.matches("[A-Za-z0-9_-]{43}")) {
            throw invalidToken();
        }
        String hash = generator.hash(rawToken);
        // Resolve the owner without loading the token before acquiring the account lock.
        // All verification and resend operations lock the same account first.
        Long userId = tokens.findOwnerIdByTokenHash(hash).orElseThrow(this::invalidToken);
        User user = users.findForUpdateById(userId).orElseThrow(this::invalidToken);
        EmailVerificationToken token = tokens.findByTokenHash(hash).orElseThrow(this::invalidToken);
        LocalDateTime now = LocalDateTime.now(clock);
        if (!user.canVerifyEmail() || !token.isUsable(now)) {
            throw invalidToken();
        }
        user.verifyEmail(now);
        token.markUsed(now);
    }

    private BadRequestException invalidToken() {
        return new BadRequestException("INVALID_VERIFICATION_TOKEN",
                "Verification link is invalid or no longer usable.");
    }
}
