package com.uniconnect.project.controller;

import com.uniconnect.project.domain.*;
import com.uniconnect.project.dto.*;
import com.uniconnect.project.service.ProjectTeammateService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/projects")
@Tag(name = "Project Teammate Finder")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid project request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Account is ineligible", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Project or application not found", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Project state conflict", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ProjectController {
    private final ProjectTeammateService projects;
    public ProjectController(ProjectTeammateService projects) { this.projects = projects; }

    @PostMapping
    @Operation(summary = "Create a project recruitment listing", description = "The title identifies the recruitment listing; a finalized project topic is not required because students may form the team first and choose the topic together. ACTIVE non-anonymized STUDENT only. Capacity includes the creator and must be 2–100. Deadline is valid through that date in Asia/Dhaka.")
    public ResponseEntity<ProjectResponse> create(@AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody ProjectRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore())
                .body(projects.create(actor, request));
    }

    @GetMapping
    @Operation(summary = "Browse projects", description = "Filters combine with AND. With neither status nor availability, returns non-expired OPEN projects (AVAILABLE and FULL). Explicit status returns that lifecycle state regardless of expiry. availability is derived: AVAILABLE, FULL, EXPIRED, or CLOSED. DELETED is never returned. Department uses the creator's current profile department.")
    public ResponseEntity<PageResponse<ProjectResponse>> browse(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) ProjectStatus status,
            @RequestParam(required = false) ProjectAvailability availability,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) String skill,
            @RequestParam(required = false) ProjectSort sort,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(projects.browse(actor, status, availability, departmentId, skill, sort, page, size));
    }

    @GetMapping("/mine")
    @Operation(summary = "List my projects", description = "Returns the creator's non-deleted OPEN and CLOSED projects, including expired projects.")
    public ResponseEntity<PageResponse<ProjectResponse>> mine(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(projects.mine(actor, page, size));
    }

    @GetMapping("/{projectId}")
    @Operation(summary = "Get project details", description = "Closed and expired projects retain direct details. Soft-deleted projects return 404.")
    public ResponseEntity<ProjectResponse> detail(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId) { return ok(projects.detail(actor, projectId)); }

    @PutMapping("/{projectId}")
    @Operation(summary = "Edit my project", description = "Creator only. OPEN or CLOSED projects may be edited. Capacity cannot be reduced below membership; extending an OPEN deadline can restore availability.")
    public ResponseEntity<ProjectResponse> update(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId, @Valid @RequestBody ProjectRequest request) {
        return ok(projects.update(actor, projectId, request));
    }

    @PostMapping("/{projectId}/close")
    @Operation(summary = "Close my project", description = "Creator only and idempotent. Existing pending applications remain reviewable.")
    public ResponseEntity<ProjectResponse> close(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId) { return ok(projects.close(actor, projectId)); }

    @PostMapping("/{projectId}/reopen")
    @Operation(summary = "Reopen my project", description = "Creator only. Requires a vacancy and a deadline valid today or later in Asia/Dhaka.")
    public ResponseEntity<ProjectResponse> reopen(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId) { return ok(projects.reopen(actor, projectId)); }

    @DeleteMapping("/{projectId}")
    @Operation(summary = "Soft-delete my project", description = "Terminal creator-only deletion. Cancels pending applications and notifies each pending applicant exactly once. Later ordinary access returns 404.")
    public ResponseEntity<Void> delete(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId, @Valid @RequestBody ProjectDeleteRequest request) {
        projects.delete(actor, projectId);
        return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
    }

    @PostMapping("/{projectId}/applications")
    @Operation(summary = "Apply to a project", description = "One lifetime application per student/project. OPEN full or expired projects reject applications. No withdrawal or reapplication.")
    public ResponseEntity<ProjectApplicationResponse> apply(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId, @Valid @RequestBody(required = false) ProjectApplicationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore())
                .body(projects.apply(actor, projectId, request));
    }

    @GetMapping("/{projectId}/applications")
    @Operation(summary = "List project applications", description = "Creator only. Pending applications remain visible and reviewable after closing or expiry.")
    public ResponseEntity<PageResponse<ProjectApplicationResponse>> applications(
            @AuthenticationPrincipal SessionPrincipal actor, @PathVariable long projectId,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(projects.applications(actor, projectId, page, size));
    }

    @PostMapping("/applications/{applicationId}/accept")
    @Operation(summary = "Accept an application", description = "Creator only. Atomically creates membership without exceeding capacity; identical retries do not duplicate membership or notification.")
    public ResponseEntity<ProjectApplicationResponse> accept(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long applicationId) { return ok(projects.accept(actor, applicationId)); }

    @PostMapping("/applications/{applicationId}/reject")
    @Operation(summary = "Reject an application", description = "Creator only. Identical retries do not duplicate notification.")
    public ResponseEntity<ProjectApplicationResponse> reject(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long applicationId) { return ok(projects.reject(actor, applicationId)); }

    @GetMapping("/{projectId}/members")
    @Operation(summary = "List project members")
    public ResponseEntity<List<ProjectMembershipResponse>> members(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId) { return ok(projects.members(actor, projectId)); }

    @GetMapping("/{projectId}/audit")
    @Operation(summary = "List project audit history", description = "Creator only.")
    public ResponseEntity<PageResponse<ProjectAuditResponse>> audit(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long projectId, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) { return ok(projects.audit(actor, projectId, page, size)); }

    private <T> ResponseEntity<T> ok(T value) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(value);
    }
}
