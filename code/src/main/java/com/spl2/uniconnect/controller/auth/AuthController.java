package com.spl2.uniconnect.controller.auth;

import com.spl2.uniconnect.dto.request.auth.ForgotPasswordRequest;
import com.spl2.uniconnect.dto.request.auth.LoginRequest;
import com.spl2.uniconnect.dto.request.auth.RegisterRequest;
import com.spl2.uniconnect.dto.request.auth.ResetPasswordRequest;
import com.spl2.uniconnect.dto.request.auth.VerifyEmailRequest;
import com.spl2.uniconnect.dto.response.auth.LoginResponse;
import com.spl2.uniconnect.dto.response.auth.RegisterResponse;
import com.spl2.uniconnect.dto.response.auth.UserResponse;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.auth.AuthService;
import com.spl2.uniconnect.service.auth.EmailVerificationService;
import com.spl2.uniconnect.service.auth.PasswordResetService;
import com.spl2.uniconnect.validation.ValidUniversityEmail;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Authentication", description = "User authentication and authorization endpoints")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private EmailVerificationService emailVerificationService;

    @Autowired
    private PasswordResetService passwordResetService;

    // =====================================================
    // POST /api/auth/register
    // =====================================================
    @PostMapping("/register")
    @Operation(summary = "Register a new user", description = "Create a new user account with email and password")
    public ResponseEntity<ApiResponse<RegisterResponse>> register(
            @Valid @RequestBody RegisterRequest request) {

        log.info("Registration request for email: {}", request.getEmail());

        RegisterResponse response = authService.register(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success(
                        "Registration successful! Please verify your email.",
                        response
                ));
    }

    // =====================================================
    // POST /api/auth/login
    // =====================================================
    @PostMapping("/login")
    @Operation(summary = "Login user", description = "Authenticate user with email and password, returns JWT token")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @Valid @RequestBody LoginRequest request) {

        log.info("Login request for email: {}", request.getEmail());

        LoginResponse response = authService.login(request);

        return ResponseEntity.ok(ApiResponse.success(
                "Login successful!",
                response
        ));
    }

    // =====================================================
    // POST /api/auth/verify-email
    // =====================================================
    @PostMapping("/verify-email")
    @Operation(summary = "Verify email", description = "Verify user email with token received in email")
    public ResponseEntity<ApiResponse<Void>> verifyEmail(
            @Valid @RequestBody VerifyEmailRequest request) {

        log.info("Email verification request");

        emailVerificationService.verifyEmail(request.getToken());

        return ResponseEntity.ok(ApiResponse.success(
                "Email verified successfully! You can now log in."
        ));
    }

    // =====================================================
    // POST /api/auth/resend-verification
    // =====================================================
    @PostMapping("/resend-verification")
    @Operation(summary = "Resend verification email", description = "Resend verification email to user")
    public ResponseEntity<ApiResponse<Void>> resendVerification(
            @RequestParam @Email @ValidUniversityEmail String email) {

        log.info("Resend verification request for email: {}", email);

        emailVerificationService.resendVerificationEmail(email);

        return ResponseEntity.ok(ApiResponse.success(
                "Verification email sent! Please check your inbox."
        ));
    }

    // =====================================================
    // POST /api/auth/forgot-password
    // =====================================================
    @PostMapping("/forgot-password")
    @Operation(summary = "Request password reset", description = "Send password reset email to user")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {

        log.info("Forgot password request for email: {}", request.getEmail());

        passwordResetService.requestPasswordReset(request.getEmail());

        // Always return success (security: don't reveal if email exists)
        return ResponseEntity.ok(ApiResponse.success(
                "If this email is registered, you will receive a password reset link."
        ));
    }

    // =====================================================
    // POST /api/auth/reset-password
    // =====================================================
    @PostMapping("/reset-password")
    @Operation(summary = "Reset password", description = "Reset user password with token")
    public ResponseEntity<ApiResponse<Void>> resetPassword(
            @Valid @RequestBody ResetPasswordRequest request) {

        log.info("Password reset request");

        passwordResetService.resetPassword(request.getToken(), request.getNewPassword());

        return ResponseEntity.ok(ApiResponse.success(
                "Password reset successfully! You can now log in with your new password."
        ));
    }

    // =====================================================
    // GET /api/auth/me (Protected)
    // =====================================================
    @GetMapping("/me")
    @Operation(summary = "Get current user", description = "Retrieve authenticated user's information")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<UserResponse>> getCurrentUser() {

        Long userId = SecurityUtils.getCurrentUserId();
        if (userId == null) {
            throw new UnauthorizedException("Not authenticated");
        }

        UserResponse response = authService.getCurrentUser(userId);

        return ResponseEntity.ok(ApiResponse.success(
                "User profile retrieved successfully",
                response
        ));
    }

    // =====================================================
    // GET /api/auth/validate-reset-token
    // =====================================================
    @GetMapping("/validate-reset-token")
    @Operation(summary = "Validate reset token", description = "Check if password reset token is valid")
    public ResponseEntity<ApiResponse<Boolean>> validateResetToken(
            @RequestParam String token) {

        boolean isValid = passwordResetService.validateResetToken(token);

        return ResponseEntity.ok(ApiResponse.success(
                isValid ? "Token is valid" : "Token is invalid or expired",
                isValid
        ));
    }
}


//PUBLIC ENDPOINTS (no JWT needed):
//───────────────────────────────────
//POST /api/auth/register              → Create account
//POST /api/auth/login                 → Login, get JWT token
//POST /api/auth/verify-email          → Verify email with token
//POST /api/auth/resend-verification   → Resend verification email
//POST /api/auth/forgot-password       → Request password reset
//POST /api/auth/reset-password        → Set new password
//GET  /api/auth/validate-reset-token  → Check if reset token valid
//
//PROTECTED ENDPOINTS (JWT required):
//─────────────────────────────────────
//GET  /api/auth/me                    → Get current user profile


//REGISTER:
//──────────
//POST /api/auth/register
//{ email, password, fullName, role }
//        ↓
//@Valid validates input
//        ↓
//authService.register()
//        ↓
//201 Created + RegisterResponse
//
//
//LOGIN:
//───────
//POST /api/auth/login
//{ email, password }
//        ↓
//authService.login()
//        ↓
//200 OK + LoginResponse (with JWT token)
//
//
//VERIFY EMAIL:
//──────────────
//POST /api/auth/verify-email
//{ token: "abc123" }
//        ↓
//emailVerificationService.verifyEmail()
//        ↓
//200 OK + success message
//
//
//FORGOT PASSWORD:
//─────────────────
//POST /api/auth/forgot-password
//{ email: "ayman@iut.ac.bd" }
//        ↓
//passwordResetService.requestPasswordReset()
//        ↓
//200 OK + "If email exists, reset link sent"
//
//
//RESET PASSWORD:
//────────────────
//POST /api/auth/reset-password
//{ token: "abc123", newPassword: "newPass" }
//        ↓
//passwordResetService.resetPassword()
//        ↓
//200 OK + "Password reset successfully"
//
//
//GET CURRENT USER:
//──────────────────
//GET /api/auth/me
//Authorization: Bearer <jwt>
//        ↓
//SecurityUtils.getCurrentUserId()
//        ↓
//authService.getCurrentUser(userId)
//        ↓
//200 OK + UserResponse


//AuthController = Hotel Reception Desk
//
//Endpoints = Different services at the desk:
//→ /register      = "I want to book a room" (create account)
//→ /login         = "I have a reservation, give me my key" (get JWT)
//→ /verify-email  = "Here is my ID to confirm booking" (verify identity)
//→ /forgot-password = "I lost my key" (request new one)
//→ /reset-password  = "Here is the lost-key form" (set new password)
//→ /me            = "What room am I in?" (get profile)
//
//The receptionist (Controller):
//→ Does NOT make the room ❌
//→ Does NOT manage bookings ❌
//→ Just takes your request ✅
//→ Calls the right department (Service) ✅
//→ Gives you the response ✅


//Internet / Frontend
//        ↓
//AuthController          ← I AM HERE
//        ↓
//Services (AuthService, EmailVerificationService, PasswordResetService)
//        ↓
//Repository
//        ↓
//Database
