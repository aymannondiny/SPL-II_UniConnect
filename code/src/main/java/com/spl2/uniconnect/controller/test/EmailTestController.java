package com.spl2.uniconnect.controller.test;

import com.spl2.uniconnect.service.email.EmailService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/test/email")
@RequiredArgsConstructor
public class EmailTestController {

    private final EmailService emailService;

    @PostMapping("/verification")
    public String testVerificationEmail(@RequestParam String email) {
        try {
            // Create a mock user for testing
            com.spl2.uniconnect.domain.user.User mockUser =
                    com.spl2.uniconnect.domain.user.User.builder()
                            .email(email)
                            .fullName("Test")
                            .role(com.spl2.uniconnect.domain.user.UserRole.STUDENT)
                            .build();

            emailService.sendVerificationEmail(mockUser, "test-token-123456789");
            return "✅ Verification email sent to: " + email;
        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }

    @PostMapping("/reset")
    public String testResetEmail(@RequestParam String email) {
        try {
            com.spl2.uniconnect.domain.user.User mockUser =
                    com.spl2.uniconnect.domain.user.User.builder()
                            .email(email)
                            .fullName("Test")
                            .role(com.spl2.uniconnect.domain.user.UserRole.STUDENT)
                            .build();

            emailService.sendPasswordResetEmail(mockUser, "test-reset-token-123456789");
            return "✅ Password reset email sent to: " + email;
        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }

    @PostMapping("/welcome")
    public String testWelcomeEmail(@RequestParam String email) {
        try {
            com.spl2.uniconnect.domain.user.User mockUser =
                    com.spl2.uniconnect.domain.user.User.builder()
                            .email(email)
                            .fullName("Test")
                            .role(com.spl2.uniconnect.domain.user.UserRole.STUDENT)
                            .build();

            emailService.sendWelcomeEmail(mockUser);
            return "✅ Welcome email sent to: " + email;
        } catch (Exception e) {
            return "❌ Error: " + e.getMessage();
        }
    }
}