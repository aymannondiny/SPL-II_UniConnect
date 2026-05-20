package com.spl2.uniconnect.service.email;

import com.spl2.uniconnect.domain.user.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    @Value("${app.email.verification-url}")
    private String verificationUrl;

    @Value("${app.email.reset-password-url}")
    private String resetPasswordUrl;

    /**
     * Send email verification
     * TODO: Implement actual email sending (Gmail SMTP / SendGrid)
     */
    public void sendVerificationEmail(User user, String token) {
        String verificationLink = verificationUrl + token;

        log.info("=".repeat(80));
        log.info("EMAIL VERIFICATION (MOCK)");
        log.info("To: {}", user.getEmail());
        log.info("Subject: Verify your UniConnect account");
        log.info("Verification Link: {}", verificationLink);
        log.info("=".repeat(80));

        // TODO: Implement actual email sending in Step 8
        // mailSender.send(...)
    }

    /**
     * Send password reset email
     * TODO: Implement actual email sending
     */
    public void sendPasswordResetEmail(User user, String token) {
        String resetLink = resetPasswordUrl + token;

        log.info("=".repeat(80));
        log.info("PASSWORD RESET EMAIL (MOCK)");
        log.info("To: {}", user.getEmail());
        log.info("Subject: Reset your UniConnect password");
        log.info("Reset Link: {}", resetLink);
        log.info("=".repeat(80));

        // TODO: Implement actual email sending in Step 8
    }
}



//VERIFICATION EMAIL:
//────────────────────
//AuthService.register()
//        ↓
//EmailVerificationService.sendVerificationEmail(user)
//        ↓
//EmailService.sendVerificationEmail(user, token)
//        ↓
//Build link: verificationUrl + token
//        ↓
//MOCK: log to console
//REAL: mailSender.send() → User's inbox
//
//
//PASSWORD RESET EMAIL:
//──────────────────────
//PasswordResetService.requestPasswordReset(email)
//        ↓
//EmailService.sendPasswordResetEmail(user, token)
//        ↓
//Build link: resetPasswordUrl + token
//        ↓
//MOCK: log to console
//REAL: mailSender.send() → User's inbox