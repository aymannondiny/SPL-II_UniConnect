package com.spl2.uniconnect.service.email;

import com.spl2.uniconnect.domain.user.User;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import java.nio.charset.StandardCharsets;

@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;
    private final SpringTemplateEngine templateEngine;

    @Value("${app.email.from}")
    private String fromEmail;

    @Value("${app.email.sender-name}")
    private String senderName;

    @Value("${app.email.verification-url}")
    private String verificationBaseUrl;

    @Value("${app.email.reset-password-url}")
    private String resetPasswordBaseUrl;

    /**
     * Send email verification link
     */
    @Async
    public void sendVerificationEmail(User user, String token) {
        try {
            String verificationLink = verificationBaseUrl + token;

            Context context = new Context();
            context.setVariable("userName", user.getFullName());
            context.setVariable("verificationLink", verificationLink);

            String subject = "Verify Your Email - UniConnect";
            sendEmailWithTemplate(user.getEmail(), subject, "email-verification", context);

            log.info("Verification email sent to: {}", user.getEmail());
        } catch (Exception e) {
            log.error("Failed to send verification email to: {}", user.getEmail(), e);
            throw new RuntimeException("Failed to send verification email", e);
        }
    }

    /**
     * Send password reset email
     */
    @Async
    public void sendPasswordResetEmail(User user, String token) {
        try {
            String resetLink = resetPasswordBaseUrl + token;

            Context context = new Context();
            context.setVariable("userName", user.getFullName());
            context.setVariable("resetLink", resetLink);

            String subject = "Reset Your Password - UniConnect";
            sendEmailWithTemplate(user.getEmail(), subject, "password-reset", context);

            log.info("Password reset email sent to: {}", user.getEmail());
        } catch (Exception e) {
            log.error("Failed to send password reset email to: {}", user.getEmail(), e);
            throw new RuntimeException("Failed to send password reset email", e);
        }
    }

    /**
     * Send welcome email after successful verification
     */
    @Async
    public void sendWelcomeEmail(User user) {
        try {
            Context context = new Context();
            context.setVariable("userName", user.getFullName());
            context.setVariable("userRole", user.getRole().toString());

            String subject = "Welcome to UniConnect!";
            sendEmailWithTemplate(user.getEmail(), subject, "welcome", context);

            log.info("Welcome email sent to: {}", user.getEmail());
        } catch (Exception e) {
            log.error("Failed to send welcome email to: {}", user.getEmail(), e);
        }
    }

    /**
     * Generic method to send email with HTML template
     */
    private void sendEmailWithTemplate(String to, String subject, String templateName, Context context) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(
                    message,
                    MimeMessageHelper.MULTIPART_MODE_MIXED_RELATED,
                    StandardCharsets.UTF_8.name()
            );

            String htmlContent = templateEngine.process(templateName, context);

            helper.setTo(to);
            helper.setFrom(fromEmail, senderName);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);

            mailSender.send(message);

        } catch (MessagingException e) {
            log.error("Failed to send email to: {}", to, e);
            throw new RuntimeException("Failed to send email", e);
        } catch (Exception e) {
            log.error("Unexpected error while sending email to: {}", to, e);
            throw new RuntimeException("Failed to send email", e);
        }
    }

    /**
     * Send plain text email (fallback)
     */
    @Async
    public void sendPlainTextEmail(String to, String subject, String body) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true);

            helper.setTo(to);
            helper.setFrom(fromEmail, senderName);
            helper.setSubject(subject);
            helper.setText(body, false);

            mailSender.send(message);
            log.info("Plain text email sent to: {}", to);

        } catch (Exception e) {
            log.error("Failed to send plain text email to: {}", to, e);
            throw new RuntimeException("Failed to send email", e);
        }
    }
}