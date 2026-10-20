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
    private final ClubLifecycleService lifecycle;
    public ClubAdministrationController(ClubService clubs, ClubLifecycleService lifecycle) {
        this.clubs = clubs; this.lifecycle = lifecycle;
    }
    @GetMapping("/{id}")
    @Operation(summary = "Read a club including retained removed records", description = "Requires SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode = "200", description = "Club record", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> get(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) {
        return ok(lifecycle.get(actor, id));
    }
    @PostMapping("/{id}/publishing/suspend")
    @Operation(summary = "Suspend new club publishing", description = "Requires SYSTEM_ADMINISTRATION context, confirmation and reason. Existing public content remains visible.")
    @ApiResponse(responseCode = "200", description = "Publishing suspended; authorized retries are unchanged", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> suspend(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubLifecycleRequest request) { return ok(lifecycle.suspend(actor, id, request)); }
    @PostMapping("/{id}/publishing/restore")
    @Operation(summary = "Restore club publishing", description = "Requires SYSTEM_ADMINISTRATION context, confirmation, reason and an eligible current administrator.")
    @ApiResponse(responseCode = "200", description = "Publishing restored; authorized retries are unchanged", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> restore(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubLifecycleRequest request) { return ok(lifecycle.restore(actor, id, request)); }
    @PostMapping({"/{id}/archive", "/{id}/remove"})
    @Operation(summary = "Archive a club", description = "Temporarily hides the club and its publications while preserving history. A system administrator can restore it later.")
    @ApiResponse(responseCode = "200", description = "Club archived; authorized retries are unchanged", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> archive(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubLifecycleRequest request) { return ok(lifecycle.archive(actor, id, request)); }
    @PostMapping("/{id}/archive/restore")
    @Operation(summary = "Restore an archived club", description = "Returns the club to its status before archiving. Requires SYSTEM_ADMINISTRATION context, confirmation, reason and an eligible current administrator.")
    @ApiResponse(responseCode = "200", description = "Archived club restored; the previous status and retained history are preserved", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> restoreArchive(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubLifecycleRequest request) { return ok(lifecycle.restoreArchive(actor, id, request)); }
    @PostMapping("/{id}/delete")
    @Operation(summary = "Delete a club", description = "Permanently removes the club from the administration list while preserving its audit history. Deleted clubs cannot be restored.")
    @ApiResponse(responseCode = "200", description = "Club deleted from the administration list", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> delete(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody ClubLifecycleRequest request) { return ok(lifecycle.delete(actor, id, request)); }

    @PostMapping
    @Operation(summary = "Create a club and appoint its first administrator atomically", description = "Requires SYSTEM_ADMIN role and selected SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode = "201", description = "Club and first assignment created", content = @Content(schema = @Schema(implementation = ClubResponse.class)))
    public ResponseEntity<ClubResponse> create(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody CreateClubRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(clubs.create(actor, request));
    }
    @GetMapping
    @Operation(summary = "List clubs for system administration", description = "Requires SYSTEM_ADMINISTRATION context; includes paused and archived clubs while omitting deleted clubs.")
    @ApiResponse(responseCode = "200", description = "Club records with current administrators", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<ClubAdminOverviewResponse>> list(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) String search, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ok(clubs.adminDirectory(actor, search, page, size));
    }
    @GetMapping("/eligible-students")
    @Operation(summary = "Search eligible student accounts for club administration", description = "Excludes suspended and anonymized accounts; requires SYSTEM_ADMINISTRATION context.")
    @ApiResponse(responseCode = "200", description = "Eligible students", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<ClubEligibleAdministratorResponse>> eligibleStudents(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "") String search, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ok(clubs.eligibleAdministrators(actor, search, page, size));
    }
    @PutMapping("/{id}")
    @Operation(summary = "Edit a club profile as a system administrator")
    @ApiResponse(responseCode = "200", description = "Updated club profile", useReturnTypeSchema = true)
    public ResponseEntity<ClubResponse> update(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody UpdateClubRequest request) { return ok(clubs.updateProfile(actor, id, request)); }
    @PostMapping("/{id}/administrators")
    @Operation(summary = "Assign an additional club administrator", description = "Additive assignment; existing administrators remain assigned.")
    @ApiResponse(responseCode = "201", description = "Administrator assigned", useReturnTypeSchema = true)
    public ResponseEntity<AssignmentResponse> assignAdministrator(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long id, @Valid @RequestBody AssignAdministratorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(clubs.assignAdministrator(actor, id, request));
    }
    @PostMapping("/{id}/administrators/{assignmentId}/remove")
    @Operation(summary = "Remove one administrator assignment", description = "Retains the assignment history and preserves at least one eligible administrator.")
    @ApiResponse(responseCode = "200", description = "Administrator assignment removed", useReturnTypeSchema = true)
    public ResponseEntity<AssignmentResponse> removeAdministrator(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long id, @PathVariable long assignmentId, @Valid @RequestBody RemoveAdministratorRequest request) {
        return ok(clubs.removeAdministrator(actor, id, assignmentId, request));
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
