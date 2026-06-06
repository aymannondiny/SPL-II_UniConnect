package com.spl2.uniconnect.controller.project;

import com.spl2.uniconnect.dto.response.project.ApplicationResponse;
import com.spl2.uniconnect.service.project.ProjectApplicationService;
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
import com.spl2.uniconnect.dto.request.project.ProjectCreateRequest;
import com.spl2.uniconnect.dto.request.project.ProjectUpdateRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.project.ProjectResponse;
import com.spl2.uniconnect.service.project.ProjectService;

@RestController
@RequestMapping("/api/projects")
@RequiredArgsConstructor
@Tag(name = "Projects", description = "Project Teammate Finder APIs")
public class ProjectController {

    private final ProjectService projectService;
    private final ProjectApplicationService projectApplicationService;

    // =====================================================
    // CREATE PROJECT
    // =====================================================

    @PostMapping
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Create project", description = "Create a new project post to find teammates")
    public ResponseEntity<ApiResponse<ProjectResponse>> createProject(
            @Valid @RequestBody ProjectCreateRequest request) {

        ProjectResponse response = projectService.createProject(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Project created successfully", response));
    }

    // =====================================================
    // READ PROJECT
    // =====================================================

    @GetMapping("/{projectId}")
    @Operation(summary = "Get project details", description = "Get complete details of a project")
    public ResponseEntity<ApiResponse<ProjectResponse>> getProjectById(
            @PathVariable Long projectId) {

        ProjectResponse response = projectService.getProjectById(projectId);

        return ResponseEntity.ok(
                ApiResponse.success("Project retrieved successfully", response)
        );
    }

    // =====================================================
    // BROWSE PROJECTS
    // =====================================================

    @GetMapping
    @Operation(summary = "Browse all projects", description = "Get all open projects with pagination")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> getAllProjects(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.getAllProjects(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Projects retrieved successfully", projects)
        );
    }

    @GetMapping("/my-projects")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get my projects", description = "Get all projects created by current user")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> getMyProjects(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.getMyProjects(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Your projects retrieved successfully", projects)
        );
    }

    // =====================================================
    // SEARCH PROJECTS
    // =====================================================

    @GetMapping("/search")
    @Operation(summary = "Search projects", description = "Search projects by title or description")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> searchProjects(
            @RequestParam(required = false) String query,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.searchProjects(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Projects found", projects)
        );
    }

    @GetMapping("/needing-teammates")
    @Operation(summary = "Get projects needing teammates", description = "Find projects that still need team members")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> getProjectsNeedingTeammates(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.getProjectsNeedingTeammates(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Projects needing teammates retrieved", projects)
        );
    }

    @GetMapping("/matching-skills")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Get projects matching my skills", description = "Find projects where you have the required skills")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> getProjectsMatchingMySkills(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.getProjectsMatchingUserSkills(
                com.spl2.uniconnect.security.SecurityUtils.getCurrentUserId(),
                pageable
        );

        return ResponseEntity.ok(
                ApiResponse.success("Matching projects retrieved", projects)
        );
    }

    @GetMapping("/with-open-applications")
    @Operation(summary = "Get projects with open applications", description = "Find projects accepting applications")
    public ResponseEntity<ApiResponse<Page<ProjectResponse>>> getProjectsWithOpenApplications(
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ProjectResponse> projects = projectService.getProjectsWithOpenApplications(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Projects with open applications retrieved", projects)
        );
    }

    // =====================================================
    // UPDATE PROJECT
    // =====================================================

    @PutMapping("/{projectId}")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Update project", description = "Update project details (creator only)")
    public ResponseEntity<ApiResponse<ProjectResponse>> updateProject(
            @PathVariable Long projectId,
            @Valid @RequestBody ProjectUpdateRequest request) {

        ProjectResponse response = projectService.updateProject(projectId, request);

        return ResponseEntity.ok(
                ApiResponse.success("Project updated successfully", response)
        );
    }

    // =====================================================
    // CLOSE / REOPEN PROJECT
    // =====================================================

    @PutMapping("/{projectId}/close")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Close project", description = "Close project (no more applications accepted)")
    public ResponseEntity<ApiResponse<ProjectResponse>> closeProject(
            @PathVariable Long projectId) {

        ProjectResponse response = projectService.closeProject(projectId);

        return ResponseEntity.ok(
                ApiResponse.success("Project closed successfully", response)
        );
    }

    @PutMapping("/{projectId}/reopen")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Reopen project", description = "Reopen a closed project")
    public ResponseEntity<ApiResponse<ProjectResponse>> reopenProject(
            @PathVariable Long projectId) {

        ProjectResponse response = projectService.reopenProject(projectId);

        return ResponseEntity.ok(
                ApiResponse.success("Project reopened successfully", response)
        );
    }

    // =====================================================
    // DELETE PROJECT
    // =====================================================

    @DeleteMapping("/{projectId}")
    @PreAuthorize("hasRole('STUDENT')")
    @Operation(summary = "Delete project", description = "Delete project (creator only, no accepted members)")
    public ResponseEntity<ApiResponse<Void>> deleteProject(
            @PathVariable Long projectId) {

        projectService.deleteProject(projectId);

        return ResponseEntity.ok(
                ApiResponse.success("Project deleted successfully")
        );
    }

    // =====================================================
// ACCEPT / REJECT APPLICATION
// =====================================================

    @PutMapping("/applications/{applicationId}/accept")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<ApplicationResponse>> acceptApplication(
            @PathVariable Long applicationId) {

        ApplicationResponse response =
                projectApplicationService.acceptApplication(applicationId);

        return ResponseEntity.ok(
                ApiResponse.success("Application accepted", response)
        );
    }

    @PutMapping("/applications/{applicationId}/reject")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<ApplicationResponse>> rejectApplication(
            @PathVariable Long applicationId) {

        ApplicationResponse response =
                projectApplicationService.rejectApplication(applicationId);

        return ResponseEntity.ok(
                ApiResponse.success("Application rejected", response)
        );
    }
}