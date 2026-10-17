package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.dto.*;
import com.uniconnect.authentication.service.SessionService;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication")
@ApiResponse(responseCode = "401", description = "Invalid credentials or session",
        content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "400", description = "Invalid request",
        content = @Content(schema = @Schema(implementation = ApiError.class)))
public class SessionController {
    private final SessionService sessions;

    public SessionController(SessionService sessions) { this.sessions = sessions; }

    @PostMapping("/login")
    @Operation(summary = "Sign in to an ACTIVE account")
    @ApiResponse(responseCode = "200", description = "Session created")
    public ResponseEntity<SessionResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(sessions.login(request));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Rotate access and refresh tokens", description = "Single-use refresh token; absolute session expiry is unchanged.")
    @ApiResponse(responseCode = "200", description = "Tokens replaced")
    public ResponseEntity<SessionResponse> refresh(@Valid @RequestBody RefreshSessionRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(sessions.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    @Operation(summary = "Revoke the current session")
    @ApiResponse(responseCode = "204", description = "Session revoked")
    @SecurityRequirement(name = "sessionBearer")
    public ResponseEntity<Void> logout(@AuthenticationPrincipal SessionPrincipal principal) {
        sessions.logout(principal);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/me")
    @Operation(summary = "Get the current authenticated account")
    @ApiResponse(responseCode = "200", description = "Current account")
    @SecurityRequirement(name = "sessionBearer")
    public ResponseEntity<CurrentUserResponse> me(@AuthenticationPrincipal SessionPrincipal principal) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(sessions.currentUser(principal));
    }
}
