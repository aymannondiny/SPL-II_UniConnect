package com.spl2.uniconnect.controller.project;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.project.ApplicationResponse;
import com.spl2.uniconnect.service.project.ProjectApplicationService;

@RestController
@RequestMapping("/api/applications")
@RequiredArgsConstructor
@Tag(name = "Applications Search", description = "User application search and management APIs")
public class SearchController {

    private final ProjectApplicationService applicationService;

    // =====================================================
    // GET MY APPLICATIONS
    // =====================================================

    @GetMapping("/my-applications")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get my applications", description = "Get all applications submitted by current user")
    public ResponseEntity<ApiResponse<Page<ApplicationResponse>>> getMyApplications(
            @PageableDefault(size = 20, sort = "appliedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ApplicationResponse> applications = applicationService.getMyApplications(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Your applications retrieved successfully", applications)
        );
    }

    @GetMapping("/my-applications/pending")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get my pending applications", description = "Get pending applications submitted by current user")
    public ResponseEntity<ApiResponse<Page<ApplicationResponse>>> getMyPendingApplications(
            @PageableDefault(size = 20, sort = "appliedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ApplicationResponse> applications = applicationService.getMyPendingApplications(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Your pending applications retrieved", applications)
        );
    }

    @GetMapping("/my-applications/accepted")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get my accepted applications", description = "Get accepted applications (my projects)")
    public ResponseEntity<ApiResponse<Page<ApplicationResponse>>> getMyAcceptedApplications(
            @PageableDefault(size = 20, sort = "respondedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ApplicationResponse> applications = applicationService.getMyAcceptedApplications(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Your accepted applications retrieved", applications)
        );
    }
}