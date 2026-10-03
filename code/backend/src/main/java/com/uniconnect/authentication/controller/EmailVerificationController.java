package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.dto.ResendVerificationRequest;
import com.uniconnect.authentication.dto.VerifyEmailRequest;
import com.uniconnect.authentication.service.EmailVerificationService;
import com.uniconnect.authentication.service.VerificationDeliveryException;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
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
public class EmailVerificationController {
    private static final Logger LOGGER = LoggerFactory.getLogger(EmailVerificationController.class);
    private final EmailVerificationService service;

    public EmailVerificationController(EmailVerificationService service) {
        this.service = service;
    }

    @PostMapping("/verify-email")
    @Operation(summary = "Verify university email", description = "Consumes a single-use link valid for 24 hours and activates a pending account. Does not create a session.")
    @ApiResponse(responseCode = "204", description = "Email verified")
    @ApiResponse(responseCode = "400", description = "Invalid request or unusable token", content = @Content(schema = @Schema(implementation = ApiError.class)))
    public ResponseEntity<Void> verify(@Valid @RequestBody VerifyEmailRequest request) {
        service.verify(request.token());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/resend-verification")
    @Operation(summary = "Request a replacement verification email", description = "Replaces outstanding links for pending accounts. Returns the same response for unknown or ineligible emails.")
    @ApiResponse(responseCode = "202", description = "Request processed")
    @ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
    public ResponseEntity<Void> resend(@Valid @RequestBody ResendVerificationRequest request) {
        try {
            service.resend(request.email());
        } catch (VerificationDeliveryException exception) {
            // The service transaction has rolled back. Preserve the previous token and
            // keep the response non-disclosing even when delivery is unavailable.
            LOGGER.warn("Verification resend delivery unavailable");
        }
        return ResponseEntity.accepted().build();
    }
}
