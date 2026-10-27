package com.uniconnect.authentication.service;

import com.uniconnect.authentication.domain.EmailVerificationToken;
import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.repository.EmailVerificationTokenRepository;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.shared.exception.BadRequestException;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EmailVerificationService {
    static final int MAX_ISSUANCES_PER_HOUR = 5;

    private final UserRepository users;
    private final EmailVerificationTokenRepository challenges;
    private final VerificationCodeGenerator generator;
    private final VerificationEmailSender sender;
    private final Clock clock;

    public EmailVerificationService(UserRepository users, EmailVerificationTokenRepository challenges,
            VerificationCodeGenerator generator, VerificationEmailSender sender, Clock clock) {
        this.users = users;
        this.challenges = challenges;
        this.generator = generator;
        this.sender = sender;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void issueForRegistration(User user) {
        issue(user, now());
    }

    @Transactional
    public void resend(String email) {
        String normalizedEmail = normalize(email);
        users.findForUpdateByEmail(normalizedEmail)
                .filter(User::canVerifyEmail)
                .ifPresent(user -> issueReplacement(user, now()));
    }

    private void issueReplacement(User user, LocalDateTime now) {
        boolean coolingDown = challenges
                .findFirstByUserUserIdOrderByCreatedAtDescTokenIdDesc(user.getUserId())
                .map(latest -> latest.getCreatedAt().plusSeconds(60).isAfter(now))
                .orElse(false);
        if (coolingDown) return;
        if (challenges.countByUserUserIdAndCreatedAtAfter(user.getUserId(), now.minusHours(1))
                >= MAX_ISSUANCES_PER_HOUR) {
            return;
        }
        issue(user, now);
    }

    private void issue(User user, LocalDateTime now) {
        EmailVerificationToken previous = challenges
                .findFirstByUserUserIdOrderByCreatedAtDescTokenIdDesc(user.getUserId()).orElse(null);
        String code = nextCodeDifferentFrom(previous, user);
        String salt = generator.generateSalt();
        String digest = generator.digest(user.getUserId(), user.getEmail(), salt, code);

        challenges.findByUserUserIdAndUsedAtIsNullAndRevokedAtIsNull(user.getUserId())
                .forEach(challenge -> challenge.revoke(now));
        challenges.saveAndFlush(new EmailVerificationToken(user, digest, salt, now));
        sender.send(user.getEmail(), code);
    }

    private String nextCodeDifferentFrom(EmailVerificationToken previous, User user) {
        String code;
        do {
            code = generator.generateCode();
        } while (previous != null && generator.matches(user.getUserId(), user.getEmail(),
                previous.getCodeSalt(), previous.getCodeDigest(), code));
        return code;
    }

    @Transactional(noRollbackFor = BadRequestException.class)
    public void verify(String email, String code) {
        String normalizedEmail = normalize(email);
        User user = users.findForUpdateByEmail(normalizedEmail).orElseThrow(this::invalidCode);
        EmailVerificationToken challenge = challenges
                .findFirstByUserUserIdAndUsedAtIsNullAndRevokedAtIsNullOrderByCreatedAtDescTokenIdDesc(user.getUserId())
                .orElseThrow(this::invalidCode);
        LocalDateTime now = now();
        if (!user.canVerifyEmail() || !challenge.isUsable(now)) {
            throw invalidCode();
        }
        if (!generator.matches(user.getUserId(), normalizedEmail, challenge.getCodeSalt(),
                challenge.getCodeDigest(), code)) {
            challenge.recordFailedAttempt(now);
            challenges.saveAndFlush(challenge);
            throw invalidCode();
        }
        user.verifyEmail(now);
        challenge.markUsed(now);
    }

    private String normalize(String email) {
        return email.strip().toLowerCase(Locale.ROOT);
    }

    private LocalDateTime now() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }

    private BadRequestException invalidCode() {
        return new BadRequestException("INVALID_VERIFICATION_CODE",
                "Verification code is invalid or no longer usable.");
    }
}
