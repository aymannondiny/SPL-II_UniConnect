package com.uniconnect.profile.controller;
import com.uniconnect.profile.dto.PrivacyRequest;
import com.uniconnect.profile.service.ProfilePrivacyService;
import jakarta.validation.Valid;

import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile/me/privacy")
@Tag(name = "Profile privacy")

@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting connection state", content = @Content(schema = @Schema(implementation = ApiError.class)))

public class ProfilePrivacyController {
    private final ProfilePrivacyService privacy;
    public ProfilePrivacyController(ProfilePrivacyService privacy) { this.privacy = privacy; }
    @GetMapping
    @Operation(summary = "Read your profile detail visibility")
    @ApiResponse(responseCode = "200", description = "Current privacy preference", content = @Content(schema = @Schema(implementation = PrivacyRequest.class)))
    public ResponseEntity<PrivacyRequest> get(@AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(privacy.get(actor));
    }
    @PatchMapping
    @Operation(summary = "Set who can view and search your additional profile details")
    @ApiResponse(responseCode = "200", description = "Saved privacy preference", content = @Content(schema = @Schema(implementation = PrivacyRequest.class)))
    public ResponseEntity<PrivacyRequest> update(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody PrivacyRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(privacy.update(actor, request));
    }
}
