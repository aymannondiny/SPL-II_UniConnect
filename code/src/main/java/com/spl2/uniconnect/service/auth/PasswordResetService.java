package com.spl2.uniconnect.service.auth;

import com.spl2.uniconnect.domain.user.TokenType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.VerificationToken;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.repository.user.VerificationTokenRepository;
import com.spl2.uniconnect.service.email.EmailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class PasswordResetService {

    private final VerificationTokenRepository tokenRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    private static final int EXPIRATION_HOURS = 1; // Password reset expires in 1 hour

    /**
     * Request password reset (send email with token)
     */
    @Transactional
    public void requestPasswordReset(String email) {
        log.info("Password reset requested for email: {}", email);

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found with email: " + email));

        // Delete any existing password reset tokens for this user
        tokenRepository.deleteByUserIdAndTokenType(
                user.getUserId(),
                TokenType.PASSWORD_RESET
        );

        // Generate new token
        String token = UUID.randomUUID().toString();

        // Create password reset token
        VerificationToken resetToken = VerificationToken.builder()
                .user(user)
                .token(token)
                .tokenType(TokenType.PASSWORD_RESET)
                .expiresAt(LocalDateTime.now().plusHours(EXPIRATION_HOURS))
                .build();

        tokenRepository.save(resetToken);

        // Send email
        emailService.sendPasswordResetEmail(user, token);

        log.info("Password reset email sent to: {}", email);
    }

    /**
     * Reset password with token
     */
    @Transactional
    public void resetPassword(String token, String newPassword) {
        log.info("Resetting password with token");

        // Find valid token
        VerificationToken resetToken = tokenRepository
                .findValidToken(token, LocalDateTime.now())
                .orElseThrow(() -> new RuntimeException("Invalid or expired password reset token"));

        // Get user
        User user = resetToken.getUser();

        // Update password
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Delete used token
        tokenRepository.delete(resetToken);

        log.info("Password reset successfully for user: {}", user.getEmail());
    }

    /**
     * Validate reset token
     */
    @Transactional(readOnly = true)
    public boolean validateResetToken(String token) {
        return tokenRepository
                .findValidToken(token, LocalDateTime.now())
                .isPresent();
    }
}



//FORGOT PASSWORD REQUEST:
//─────────────────────────
//User enters email on "Forgot Password" page
//        ↓
//POST /api/auth/forgot-password
//{ email: "ayman@iut.ac.bd" }
//        ↓
//requestPasswordReset(email)
//        ↓
//Token created → Email sent
//        ↓
//User checks email
//
//
//USER CLICKS LINK:
//──────────────────
//Click: https://yourapp.com/reset-password?token=abc123
//        ↓
//Frontend calls: GET /api/auth/validate-reset-token?token=abc123
//        ↓
//validateResetToken("abc123") → true
//        ↓
//Show "Enter new password" form to user
//
//
//USER SUBMITS NEW PASSWORD:
//────────────────────────────
//POST /api/auth/reset-password
//{ token: "abc123", newPassword: "newSecurePassword" }
//        ↓
//resetPassword(token, newPassword)
//        ↓
//Token validated → password hashed → stored → token deleted
//        ↓
//User can now login with new password ✅
//
//
//IF TOKEN EXPIRED:
//──────────────────
//User tries old link after 1 hour
//        ↓
//validateResetToken("abc123") → false
//        ↓
//Show "Link expired, click here to resend"
//        ↓
//User requests forgot password again → new token created → new email sent