package com.spl2.uniconnect.controller.career;

import com.spl2.uniconnect.domain.career.JobType;
import com.spl2.uniconnect.dto.request.career.CreateJobRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.common.PageResponse;
import com.spl2.uniconnect.dto.response.career.JobPostingResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.career.CareerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/career")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Career Board", description = "Job and Internship APIs")
public class CareerController {

    private final CareerService careerService;

    @PostMapping("/jobs")
    @Operation(summary = "Post a job", description = "Alumni post job/internship opportunities")
    @PreAuthorize("hasRole('ALUMNI')")
    public ResponseEntity<ApiResponse<JobPostingResponse>> createJob(
            @Valid @RequestBody CreateJobRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        if (currentUserId == null) throw new UnauthorizedException("Not authenticated");
        log.info("POST /api/career/jobs - by userId: {}", currentUserId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Job posted successfully",
                        careerService.createJobPosting(request, currentUserId)));
    }

    @GetMapping("/jobs")
    @Operation(summary = "Browse all jobs")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<JobPostingResponse>>> getAllJobs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        Page<JobPostingResponse> jobs = careerService.getAllJobs(
                PageRequest.of(page, size), currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Jobs retrieved",
                PageResponse.of(jobs)));
    }

    @GetMapping("/jobs/search")
    @Operation(summary = "Search jobs by title, company or description")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<JobPostingResponse>>> searchJobs(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        Page<JobPostingResponse> jobs = careerService.searchJobs(
                query, PageRequest.of(page, size), currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Jobs retrieved",
                PageResponse.of(jobs)));
    }

    @GetMapping("/jobs/type/{jobType}")
    @Operation(summary = "Filter by job type")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<JobPostingResponse>>> getJobsByType(
            @PathVariable JobType jobType,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        Page<JobPostingResponse> jobs = careerService.getJobsByType(
                jobType, PageRequest.of(page, size), currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Jobs retrieved",
                PageResponse.of(jobs)));
    }

    @GetMapping("/jobs/saved")
    @Operation(summary = "Get my saved jobs")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<PageResponse<JobPostingResponse>>> getMySavedJobs(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        if (currentUserId == null) throw new UnauthorizedException("Not authenticated");
        Page<JobPostingResponse> jobs = careerService.getMySavedJobs(
                PageRequest.of(page, size), currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Saved jobs retrieved",
                PageResponse.of(jobs)));
    }

    @GetMapping("/jobs/{jobId}")
    @Operation(summary = "Get job details")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<JobPostingResponse>> getJobById(
            @PathVariable Long jobId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        return ResponseEntity.ok(ApiResponse.success("Job retrieved",
                careerService.getJobById(jobId, currentUserId)));
    }

    @PostMapping("/jobs/{jobId}/save")
    @Operation(summary = "Save a job for later")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<Void>> saveJob(@PathVariable Long jobId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        if (currentUserId == null) throw new UnauthorizedException("Not authenticated");
        careerService.saveJob(jobId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Job saved", null));
    }

    @DeleteMapping("/jobs/{jobId}/save")
    @Operation(summary = "Remove job from saved")
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<Void>> unsaveJob(@PathVariable Long jobId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        if (currentUserId == null) throw new UnauthorizedException("Not authenticated");
        careerService.unsaveJob(jobId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Job removed from saved", null));
    }

    @DeleteMapping("/jobs/{jobId}")
    @Operation(summary = "Delete a job posting")
    @PreAuthorize("hasRole('ALUMNI') or hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteJob(@PathVariable Long jobId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        if (currentUserId == null) throw new UnauthorizedException("Not authenticated");
        careerService.deleteJobPosting(jobId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Job deleted", null));
    }

    @GetMapping("/jobs/companies")
    @Operation(summary = "Get all companies for filter")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getAllCompanies() {
        return ResponseEntity.ok(ApiResponse.success("Companies retrieved",
                careerService.getAllCompanies()));
    }

    @GetMapping("/jobs/locations")
    @Operation(summary = "Get all locations for filter")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getAllLocations() {
        return ResponseEntity.ok(ApiResponse.success("Locations retrieved",
                careerService.getAllLocations()));
    }
}