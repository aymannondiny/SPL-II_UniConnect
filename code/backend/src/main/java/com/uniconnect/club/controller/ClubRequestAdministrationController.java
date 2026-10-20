package com.uniconnect.club.controller;

import com.uniconnect.club.domain.ClubCreationRequestStatus;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.ClubCreationRequestService;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/club-requests")
@Tag(name = "Club request administration")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "System administrator context required", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ClubRequestAdministrationController {
    private final ClubCreationRequestService requests;
    public ClubRequestAdministrationController(ClubCreationRequestService requests) { this.requests = requests; }

    @GetMapping
    @Operation(summary = "Review club creation requests", description = "Omit status to include processed request history.")
    public ResponseEntity<List<ClubCreationRequestResponse>> review(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) ClubCreationRequestStatus status) {
        return ok(requests.review(actor, status));
    }
    @PostMapping("/{id}/approve")
    @Operation(summary = "Approve and create a requested club", description = "The requester is assigned as a club administrator in the same transaction.")
    public ResponseEntity<ClubCreationRequestResponse> approve(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) {
        return ok(requests.approve(actor, id));
    }
    @PostMapping("/{id}/reject")
    @Operation(summary = "Reject and retain a club creation request")
    public ResponseEntity<ClubCreationRequestResponse> reject(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubCreationRequestDecision body) { return ok(requests.reject(actor, id, body)); }
    private <T> ResponseEntity<T> ok(T value) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(value); }
}
