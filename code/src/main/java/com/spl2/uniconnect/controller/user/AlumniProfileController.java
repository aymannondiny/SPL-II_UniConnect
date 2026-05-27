package com.spl2.uniconnect.controller.user;

import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.common.PageResponse;
import com.spl2.uniconnect.dto.response.user.AlumniProfileResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.user.AlumniProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/profiles")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Alumni Profile", description = "Alumni Profile Management APIs")
public class AlumniProfileController {

    private final AlumniProfileService alumniProfileService;

    // =====================================================
    // GET ENDPOINTS
    // =====================================================

    /**
     * Get alumni profile by user ID
     * GET /api/profiles/alumni/{userId}
     */
    @GetMapping("/alumni/{userId}")
    @Operation(
            summary = "Get alumni profile",
            description = "Get alumni profile by user ID"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AlumniProfileResponse>> getAlumniProfile(
            @Parameter(description = "User ID of the alumni")
            @PathVariable Long userId) {

        log.info("GET /api/profiles/alumni/{}", userId);

        AlumniProfileResponse response = alumniProfileService
                .getAlumniProfileByUserId(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni profile retrieved successfully", response)
        );
    }

    /**
     * Get MY alumni profile
     * GET /api/profiles/alumni/me
     */
    @GetMapping("/alumni/me")
    @Operation(
            summary = "Get my alumni profile",
            description = "Get the authenticated alumni's own profile"
    )
    @PreAuthorize("hasRole('ALUMNI')")
    public ResponseEntity<ApiResponse<AlumniProfileResponse>> getMyAlumniProfile() {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("GET /api/profiles/alumni/me - userId: {}", currentUserId);

        AlumniProfileResponse response = alumniProfileService
                .getAlumniProfileByUserId(currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni profile retrieved successfully", response)
        );
    }

    // =====================================================
    // UPDATE ENDPOINTS
    // =====================================================

    /**
     * Update alumni profile
     * PUT /api/profiles/alumni/{userId}
     */
    @PutMapping("/alumni/{userId}")
    @Operation(
            summary = "Update alumni profile",
            description = "Update alumni profile"
    )
    @PreAuthorize("hasRole('ALUMNI') or hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<AlumniProfileResponse>> updateAlumniProfile(
            @Parameter(description = "User ID of the alumni")
            @PathVariable Long userId,
            @Valid @RequestBody UpdateAlumniProfileRequest request) {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("PUT /api/profiles/alumni/{} - by userId: {}", userId, currentUserId);

        AlumniProfileResponse response = alumniProfileService
                .updateAlumniProfile(userId, request, currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni profile updated successfully", response)
        );
    }

    // =====================================================
    // SEARCH & FILTER ENDPOINTS
    // =====================================================

    /**
     * Search alumni
     * GET /api/profiles/alumni/search?query=software
     */
    @GetMapping("/alumni/search")
    @Operation(
            summary = "Search alumni",
            description = "Search alumni by name, company, position, or background"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> searchAlumni(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "asc") String sortDir) {

        log.info("GET /api/profiles/alumni/search - query: {}", query);

        Sort sort = sortDir.equalsIgnoreCase("desc")
                ? Sort.by("graduationYear").descending()
                : Sort.by("graduationYear").ascending();

        Pageable pageable = PageRequest.of(page, size, sort);

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .searchAlumni(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Get alumni by graduation year
     * GET /api/profiles/alumni/year/{year}
     */
    @GetMapping("/alumni/year/{year}")
    @Operation(
            summary = "Get alumni by graduation year",
            description = "Get all alumni who graduated in a specific year"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByYear(
            @PathVariable Integer year,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/year/{}", year);

        Pageable pageable = PageRequest.of(page, size);

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByGraduationYear(year, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Get alumni by graduation year range
     * GET /api/profiles/alumni/year-range?start=2020&end=2024
     */
    @GetMapping("/alumni/year-range")
    @Operation(
            summary = "Get alumni by year range",
            description = "Get alumni who graduated between start and end year"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByYearRange(
            @RequestParam Integer start,
            @RequestParam Integer end,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/year-range?start={}&end={}", start, end);

        Pageable pageable = PageRequest.of(page, size,
                Sort.by("graduationYear").descending());

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByYearRange(start, end, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Get alumni by programme
     * GET /api/profiles/alumni/programme/{programmeId}
     */
    @GetMapping("/alumni/programme/{programmeId}")
    @Operation(
            summary = "Get alumni by programme",
            description = "Get alumni who graduated from a specific programme"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByProgramme(
            @PathVariable Long programmeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/programme/{}", programmeId);

        Pageable pageable = PageRequest.of(page, size,
                Sort.by("graduationYear").descending());

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByProgramme(programmeId, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }


    /**
     * Get alumni by company
     * GET /api/profiles/alumni/company?query=Google
     */
    @GetMapping("/alumni/company")
    @Operation(
            summary = "Get alumni by company",
            description = "Get alumni working at a specific company"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByCompany(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/company?query={}", query);

        Pageable pageable = PageRequest.of(page, size);

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByCompany(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Get alumni by industry
     * GET /api/profiles/alumni/industry?query=Technology
     */
    @GetMapping("/alumni/industry")
    @Operation(
            summary = "Get alumni by industry",
            description = "Get alumni working in a specific industry"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByIndustry(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/industry?query={}", query);

        Pageable pageable = PageRequest.of(page, size);

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByIndustry(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Get alumni by multiple filters
     * GET /api/profiles/alumni/filter?year=2020&industry=Tech&company=Google
     */
    @GetMapping("/alumni/filter")
    @Operation(
            summary = "Get alumni by filters",
            description = "Get alumni by multiple optional filters"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<AlumniProfileResponse>>> getAlumniByFilters(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) String industry,
            @RequestParam(required = false) String company,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/alumni/filter - year:{} industry:{} company:{}",
                year, industry, company);

        Pageable pageable = PageRequest.of(page, size);

        Page<AlumniProfileResponse> alumniPage = alumniProfileService
                .getAlumniByFilters(year, industry, company, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully",
                        PageResponse.of(alumniPage))
        );
    }

    /**
     * Full text search alumni
     * GET /api/profiles/alumni/fts?query=software engineer
     */
    @GetMapping("/alumni/fts")
    @Operation(
            summary = "Full text search alumni",
            description = "PostgreSQL full-text search for alumni"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<AlumniProfileResponse>>> fullTextSearch(
            @RequestParam String query) {

        log.info("GET /api/profiles/alumni/fts - query: {}", query);

        List<AlumniProfileResponse> alumni = alumniProfileService
                .fullTextSearchAlumni(query);

        return ResponseEntity.ok(
                ApiResponse.success("Alumni retrieved successfully", alumni)
        );
    }

    /**
     * Get all industries
     * GET /api/profiles/alumni/industries
     */
    @GetMapping("/alumni/industries")
    @Operation(
            summary = "Get all industries",
            description = "Get all distinct industries where alumni work"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getAllIndustries() {

        log.info("GET /api/profiles/alumni/industries");

        List<String> industries = alumniProfileService.getAllIndustries();

        return ResponseEntity.ok(
                ApiResponse.success("Industries retrieved successfully", industries)
        );
    }

    /**
     * Get all companies
     * GET /api/profiles/alumni/companies
     */
    @GetMapping("/alumni/companies")
    @Operation(
            summary = "Get all companies",
            description = "Get all distinct companies where alumni work"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getAllCompanies() {

        log.info("GET /api/profiles/alumni/companies");

        List<String> companies = alumniProfileService.getAllCompanies();

        return ResponseEntity.ok(
                ApiResponse.success("Companies retrieved successfully", companies)
        );
    }
}


//API Endpoints Summary:
//Method	Endpoint	Description	Role
//GET	/api/profiles/alumni/{userId}	Get alumni profile	All
//GET	/api/profiles/alumni/me	Get my profile	Alumni
//PUT	/api/profiles/alumni/{userId}	Update profile	Alumni/Admin
//GET	/api/profiles/alumni/search	Search alumni	All
//GET	/api/profiles/alumni/year/{year}	Get by grad year	All
//GET	/api/profiles/alumni/year-range	Get by year range	All
//GET	/api/profiles/alumni/major	Get by major	All
//GET	/api/profiles/alumni/company	Get by company	All
//GET	/api/profiles/alumni/industry	Get by industry	All
//GET	/api/profiles/alumni/filter	Get by multiple filters	All
//GET	/api/profiles/alumni/fts	Full text search	All
//GET	/api/profiles/alumni/industries	Get all industries	All
//GET	/api/profiles/alumni/companies	Get all companies	All