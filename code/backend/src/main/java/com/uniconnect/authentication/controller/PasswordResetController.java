package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.dto.ForgotPasswordRequest;
import com.uniconnect.authentication.dto.ResetPasswordRequest;
import com.uniconnect.authentication.service.PasswordResetService;
import com.uniconnect.authentication.service.PasswordResetDeliveryException;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication")
public class PasswordResetController {
    private static final Logger LOGGER = LoggerFactory.getLogger(PasswordResetController.class);
    private final PasswordResetService service;

    public PasswordResetController(PasswordResetService service) { this.service = service; }

    @PostMapping("/forgot-password")
    @Operation(summary = "Request a password reset link", description = "Returns the same empty response for unknown or ineligible accounts and unavailable email delivery.")
    @ApiResponse(responseCode = "202", description = "Request processed")
    @ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
    public ResponseEntity<Void> forgot(@Valid @RequestBody ForgotPasswordRequest request) {
        try {
            service.requestReset(request.email());
        } catch (PasswordResetDeliveryException e) {
            // The transaction has rolled back, preserving any previous usable link.
            LOGGER.warn("Password reset email delivery unavailable");
        }
        return ResponseEntity.accepted().build();
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password", description = "Consumes a one-hour link, replaces the password, and revokes all sessions atomically. Account status is unchanged; no session is created.")
    @ApiResponse(responseCode = "204", description = "Password reset")
    @ApiResponse(responseCode = "400", description = "Invalid request, password or token", content = @Content(schema = @Schema(implementation = ApiError.class)))
    public ResponseEntity<Void> reset(@Valid @RequestBody ResetPasswordRequest request) {
        service.reset(request.token(), request.newPassword());
        return ResponseEntity.noContent().build();
    }
}
