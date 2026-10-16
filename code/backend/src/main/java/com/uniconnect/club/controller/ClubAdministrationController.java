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
@RequestMapping("/api/v1/admin/clubs")
@Tag(name = "Club administration")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Role or selected context does not authorize this action", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting club or assignment state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ClubAdministrationController {
    private final ClubService clubs;
    public ClubAdministrationController(ClubService clubs) { this.clubs = clubs; }
    @PostMapping
    @Operation(summary = "Create a club and appoint its first administrator atomically", description = "Requires SYSTEM_ADMIN role and selected SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode = "201", description = "Club and first assignment created", content = @Content(schema = @Schema(implementation = ClubResponse.class)))
    public ResponseEntity<ClubResponse> create(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody CreateClubRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(clubs.create(actor, request));
    }
    @PostMapping("/{id}/administrator/replace")
    @Operation(summary = "Replace the club administrator atomically", description = "Requires SYSTEM_ADMINISTRATION context. Promoting a current representative revokes that representative assignment before granting administrator access.")
    @ApiResponse(responseCode = "200", description = "Successful response", useReturnTypeSchema = true)
    public ResponseEntity<AssignmentResponse> replace(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ReplaceAdministratorRequest request) { return ok(clubs.replaceAdministrator(actor, id, request)); }
    @GetMapping("/{id}/audit")
    @Operation(summary = "Read retained club authority audit history", description = "Requires SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode = "200", description = "Successful response", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<ClubAuditResponse>> audit(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) { return ok(clubs.auditHistory(actor, id, page, size)); }
    private <T> ResponseEntity<T> ok(T result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
}
