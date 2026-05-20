package com.spl2.uniconnect.service.auth;

import com.spl2.uniconnect.domain.user.TokenType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.VerificationToken;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.repository.user.VerificationTokenRepository;
import com.spl2.uniconnect.service.email.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailVerificationService {

    private final VerificationTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    private static final int EXPIRATION_HOURS = 24;

    /**
     * Send verification email to user
     */
    @Transactional
    public void sendVerificationEmail(User user) {
        log.info("Sending verification email to: {}", user.getEmail());

        // Delete any existing verification tokens for this user
        tokenRepository.deleteByUserIdAndTokenType(
                user.getUserId(),
                TokenType.EMAIL_VERIFICATION
        );

        // Generate new token
        String token = UUID.randomUUID().toString();

        // Create verification token entity
        VerificationToken verificationToken = VerificationToken.builder()
                .user(user)
                .token(token)
                .tokenType(TokenType.EMAIL_VERIFICATION)
                .expiresAt(LocalDateTime.now().plusHours(EXPIRATION_HOURS))
                .build();

        tokenRepository.save(verificationToken);

        // Send email
        emailService.sendVerificationEmail(user, token);

        log.info("Verification email sent successfully to: {}", user.getEmail());
    }

    /**
     * Verify email with token
     */
    @Transactional
    public void verifyEmail(String token) {
        log.info("Verifying email with token");

        // Find valid token
        VerificationToken verificationToken = tokenRepository
                .findValidToken(token, LocalDateTime.now())
                .orElseThrow(() -> new RuntimeException("Invalid or expired verification token"));

        // Get user
        User user = verificationToken.getUser();

        // Check if already verified
        if (user.getEmailVerified()) {
            log.info("Email already verified for user: {}", user.getEmail());
            return;
        }

        // Mark email as verified
        user.setEmailVerified(true);
        userRepository.save(user);

        // Delete used token
        tokenRepository.delete(verificationToken);

        log.info("Email verified successfully for user: {}", user.getEmail());
    }

    /**
     * Resend verification email
     */
    @Transactional
    public void resendVerificationEmail(String email) {
        log.info("Resending verification email to: {}", email);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));

        if (user.getEmailVerified()) {
            throw new RuntimeException("Email already verified");
        }

        sendVerificationEmail(user);
    }

    /**
     * Cleanup expired tokens (scheduled job can call this)
     */
    @Transactional
    public int cleanupExpiredTokens() {
        int deleted = tokenRepository.deleteAllExpiredTokens(LocalDateTime.now());
        log.info("Cleaned up {} expired verification tokens", deleted);
        return deleted;
    }
}


//REGISTRATION:
//─────────────
//User registers
//        ↓
//sendVerificationEmail()
//        ↓
//Token created in DB (expires in 24hrs)
//        ↓
//Email sent with link
//
//
//USER CLICKS LINK:
//──────────────────
//Click: /verify?token=abc123
//        ↓
//verifyEmail("abc123")
//        ↓
//Token valid? → user.emailVerified = true
//Token invalid/expired? → error
//
//
//TOKEN EXPIRED:
//───────────────
//User: "I never got the email"
//        ↓
//POST /resend-verification
//        ↓
//resendVerificationEmail(email)
//        ↓
//Old token deleted → new token created → new email sent
//
//
//HOUSEKEEPING:
//──────────────
//Every day at 2 AM
//        ↓
//cleanupExpiredTokens()
//        ↓
//All expired tokens deleted from DB