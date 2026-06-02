package com.spl2.uniconnect.controller.project;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.spl2.uniconnect.dto.request.project.ApplicationRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.project.ApplicationResponse;
import com.spl2.uniconnect.service.project.ProjectApplicationService;

@RestController
@RequestMapping("/api/projects/{projectId}/applications")
@RequiredArgsConstructor
@Tag(name = "Project Applications", description = "Project application management APIs")
public class ApplicationController {

    private final ProjectApplicationService applicationService;

    // =====================================================
    // APPLY TO PROJECT
    // =====================================================

    @PostMapping
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Apply to project", description = "Submit an application to join a project")
    public ResponseEntity<ApiResponse<ApplicationResponse>> applyToProject(
            @PathVariable Long projectId,
            @Valid @RequestBody ApplicationRequest request) {

        ApplicationResponse response = applicationService.applyToProject(projectId, request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Application submitted successfully", response));
    }

    // =====================================================
    // GET APPLICATIONS
    // =====================================================

    @GetMapping
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get project applications", description = "Get all applications for a project (creator only)")
    public ResponseEntity<ApiResponse<Page<ApplicationResponse>>> getApplicationsByProject(
            @PathVariable Long projectId,
            @PageableDefault(size = 20, sort = "appliedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ApplicationResponse> applications = applicationService.getApplicationsByProject(projectId, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Applications retrieved successfully", applications)
        );
    }

    @GetMapping("/pending")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get pending applications", description = "Get pending applications for a project")
    public ResponseEntity<ApiResponse<Page<ApplicationResponse>>> getPendingApplications(
            @PathVariable Long projectId,
            @PageableDefault(size = 20, sort = "appliedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ApplicationResponse> applications = applicationService.getPendingApplicationsByProject(projectId, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Pending applications retrieved", applications)
        );
    }

    // =====================================================
    // MANAGE APPLICATIONS
    // =====================================================

    @PutMapping("/{applicationId}/accept")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Accept application", description = "Accept an application (creator only)")
    public ResponseEntity<ApiResponse<ApplicationResponse>> acceptApplication(
            @PathVariable Long projectId,
            @PathVariable Long applicationId) {

        ApplicationResponse response = applicationService.acceptApplication(applicationId);

        return ResponseEntity.ok(
                ApiResponse.success("Application accepted successfully", response)
        );
    }

    @PutMapping("/{applicationId}/reject")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Reject application", description = "Reject an application (creator only)")
    public ResponseEntity<ApiResponse<Void>> rejectApplication(
            @PathVariable Long projectId,
            @PathVariable Long applicationId) {

        applicationService.rejectApplication(applicationId);

        return ResponseEntity.ok(
                ApiResponse.success("Application rejected successfully")
        );
    }
}