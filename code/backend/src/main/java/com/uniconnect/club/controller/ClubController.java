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
@RequestMapping("/api/v1/clubs")
@Tag(name = "Clubs")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Role or selected context does not authorize this action", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting club or assignment state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ClubController {
    private final ClubService clubs;
    public ClubController(ClubService clubs) { this.clubs = clubs; }
    @GetMapping
    @Operation(summary = "Browse non-removed clubs", description = "Authenticated ACTIVE users; publishing-suspended clubs remain visible. Search matches name/category. Size 1–50, page starts at 0.")
    public ResponseEntity<PageResponse<ClubResponse>> list(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) String search, @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(clubs.directory(actor, search, page, size));
    }
    @GetMapping("/{id}")
    @Operation(summary = "View a club profile")
    public ResponseEntity<ClubResponse> get(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return ok(clubs.get(actor, id)); }
    @GetMapping("/{id}/operators")
    @Operation(summary = "List current or historical club assignments", description = "Requires this club's selected administrator context. status: CURRENT, REVOKED, ALL.")
    public ResponseEntity<PageResponse<AssignmentResponse>> operators(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @RequestParam(defaultValue = "CURRENT") String status, @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(clubs.operators(actor, id, status, page, size));
    }
    @PostMapping("/{id}/representatives")
    @Operation(summary = "Assign an ACTIVE student as a representative", description = "Requires this club's selected administrator context.")
    @ApiResponse(responseCode = "201", description = "Representative assigned", content = @Content(schema = @Schema(implementation = AssignmentResponse.class)))
    public ResponseEntity<AssignmentResponse> assign(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id, @Valid @RequestBody AssignRepresentativeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(clubs.assignRepresentative(actor, id, request));
    }
    @PostMapping("/{id}/representatives/{assignmentId}/revoke")
    @Operation(summary = "Revoke representative access with confirmation and reason")
    public ResponseEntity<AssignmentResponse> revoke(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id, @PathVariable long assignmentId,
            @Valid @RequestBody RevokeRepresentativeRequest request) { return ok(clubs.revokeRepresentative(actor, id, assignmentId, request)); }
    private <T> ResponseEntity<T> ok(T result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
}
