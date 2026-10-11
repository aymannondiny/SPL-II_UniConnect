package com.uniconnect.club.controller;

import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.exception.ApiError;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth/contexts")
@Tag(name = "Dashboard contexts")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Role or selected context does not authorize this action", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting club or assignment state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ContextController {
    private final ClubContextService contexts;
    public ContextController(ClubContextService contexts) { this.contexts = contexts; }
    @GetMapping
    @Operation(summary = "Get current session selection and available dashboard contexts", description = "Defaults to PERSONAL. Revoked, removed-club, or ineligible assignments never authorize CLUB access.")
    public ResponseEntity<ContextsResponse> get(@AuthenticationPrincipal SessionPrincipal actor) { return ok(contexts.get(actor)); }
    @PutMapping("/active")
    @Operation(summary = "Select this session's active dashboard", description = "CLUB requires assignmentId; PERSONAL and SYSTEM_ADMINISTRATION must omit it. No password or new token is needed.")
    public ResponseEntity<ContextsResponse> select(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody SelectContextRequest request) {
        return ok(contexts.select(actor, request));
    }
    private ResponseEntity<ContextsResponse> ok(ContextsResponse result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
}
