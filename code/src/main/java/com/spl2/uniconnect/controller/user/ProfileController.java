package com.spl2.uniconnect.controller.user;

import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.common.PageResponse;
import com.spl2.uniconnect.dto.response.user.ClubProfileResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.user.ClubProfileService;
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
@Tag(name = "Club Profile", description = "Club Profile Management APIs")
public class ProfileController {

    private final ClubProfileService clubProfileService;

    // =====================================================
    // GET ENDPOINTS
    // =====================================================

    /**
     * Get club profile by user ID
     * GET /api/profiles/clubs/{userId}
     * FR-2.6: View Profile
     */
    @GetMapping("/clubs/{userId}")
    @Operation(
            summary = "Get club profile by userId",
            description = "Get club profile by user ID - FR-2.6"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ClubProfileResponse>> getClubProfile(
            @Parameter(description = "User ID of the club")
            @PathVariable Long userId) {

        log.info("GET /api/profiles/clubs/{}", userId);

        ClubProfileResponse response = clubProfileService
                .getClubProfileByUserId(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Club profile retrieved successfully", response)
        );
    }

    /**
     * Get MY club profile (authenticated club user)
     * GET /api/profiles/clubs/me
     */
    @GetMapping("/clubs/me")
    @Operation(
            summary = "Get my club profile",
            description = "Get the authenticated club's own profile"
    )
    @PreAuthorize("hasRole('CLUB_ADMIN')")
    public ResponseEntity<ApiResponse<ClubProfileResponse>> getMyClubProfile() {

        // SecurityUtils is static - no injection needed
        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("GET /api/profiles/clubs/me - userId: {}", currentUserId);

        ClubProfileResponse response = clubProfileService
                .getClubProfileByUserId(currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Club profile retrieved successfully", response)
        );
    }

    // =====================================================
    // UPDATE ENDPOINTS
    // =====================================================

    /**
     * Update club profile
     * PUT /api/profiles/clubs/{userId}
     * FR-2.5: Edit Profile
     */
    @PutMapping("/clubs/{userId}")
    @Operation(
            summary = "Update club profile",
            description = "Update club profile - FR-2.5"
    )
    @PreAuthorize("hasRole('CLUB_ADMIN') or hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<ClubProfileResponse>> updateClubProfile(
            @Parameter(description = "User ID of the club")
            @PathVariable Long userId,
            @Valid @RequestBody UpdateClubProfileRequest request) {

        // SecurityUtils is static - no injection needed
        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("PUT /api/profiles/clubs/{} - by userId: {}", userId, currentUserId);

        ClubProfileResponse response = clubProfileService
                .updateClubProfile(userId, request, currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Club profile updated successfully", response)
        );
    }

    // =====================================================
    // SEARCH & FILTER ENDPOINTS
    // =====================================================

    /**
     * Search clubs by name or description
     * GET /api/profiles/clubs/search?query=tech&page=0&size=10
     */
    @GetMapping("/clubs/search")
    @Operation(
            summary = "Search clubs",
            description = "Search clubs by name or description with pagination"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<ClubProfileResponse>>> searchClubs(
            @Parameter(description = "Search query")
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "clubName") String sortBy,
            @RequestParam(defaultValue = "asc") String sortDir) {

        log.info("GET /api/profiles/clubs/search - query: {}", query);

        Sort sort = sortDir.equalsIgnoreCase("desc")
                ? Sort.by(sortBy).descending()
                : Sort.by(sortBy).ascending();

        Pageable pageable = PageRequest.of(page, size, sort);

        Page<ClubProfileResponse> clubPage = clubProfileService
                .searchClubs(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Clubs retrieved successfully",
                        PageResponse.of(clubPage))
        );
    }

    /**
     * Get clubs by category
     * GET /api/profiles/clubs/category/{category}
     */
    @GetMapping("/clubs/category/{category}")
    @Operation(
            summary = "Get clubs by category",
            description = "Get all clubs filtered by category with pagination"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<ClubProfileResponse>>> getClubsByCategory(
            @Parameter(description = "Club category")
            @PathVariable String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/clubs/category/{}", category);

        Pageable pageable = PageRequest.of(page, size,
                Sort.by("clubName").ascending());

        Page<ClubProfileResponse> clubPage = clubProfileService
                .getClubsByCategory(category, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Clubs retrieved successfully",
                        PageResponse.of(clubPage))
        );
    }

    /**
     * Get clubs by department
     * GET /api/profiles/clubs/department/{departmentId}
     */
    @GetMapping("/clubs/department/{departmentId}")
    @Operation(
            summary = "Get clubs by department",
            description = "Get all clubs belonging to a specific department"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ClubProfileResponse>>> getClubsByDepartment(
            @Parameter(description = "Department ID")
            @PathVariable Long departmentId) {

        log.info("GET /api/profiles/clubs/department/{}", departmentId);

        List<ClubProfileResponse> clubs = clubProfileService
                .getClubsByDepartment(departmentId);

        return ResponseEntity.ok(
                ApiResponse.success("Clubs retrieved successfully", clubs)
        );
    }

    /**
     * Full text search clubs (PostgreSQL)
     * GET /api/profiles/clubs/fts?query=robotics
     */
    @GetMapping("/clubs/fts")
    @Operation(
            summary = "Full text search clubs",
            description = "PostgreSQL full-text search for clubs"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ClubProfileResponse>>> fullTextSearch(
            @Parameter(description = "Search query")
            @RequestParam String query) {

        log.info("GET /api/profiles/clubs/fts - query: {}", query);

        List<ClubProfileResponse> clubs = clubProfileService
                .fullTextSearchClubs(query);

        return ResponseEntity.ok(
                ApiResponse.success("Clubs retrieved successfully", clubs)
        );
    }

    /**
     * Get all distinct categories
     * GET /api/profiles/clubs/categories
     */
    @GetMapping("/clubs/categories")
    @Operation(
            summary = "Get all categories",
            description = "Get all distinct club categories"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getAllCategories() {

        log.info("GET /api/profiles/clubs/categories");

        List<String> categories = clubProfileService.getAllCategories();

        return ResponseEntity.ok(
                ApiResponse.success("Categories retrieved successfully", categories)
        );
    }

    /**
     * Get open clubs (no department)
     * GET /api/profiles/clubs/open
     */
    @GetMapping("/clubs/open")
    @Operation(
            summary = "Get open clubs",
            description = "Get all clubs not tied to any department"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ClubProfileResponse>>> getOpenClubs() {

        log.info("GET /api/profiles/clubs/open");

        List<ClubProfileResponse> clubs = clubProfileService.getOpenClubs();

        return ResponseEntity.ok(
                ApiResponse.success("Open clubs retrieved successfully", clubs)
        );
    }
}


//Complete URL Map
//
//
//GET    /api/profiles/clubs/{userId}          → Get specific club profile
//GET    /api/profiles/clubs/me                → Get MY club profile
//PUT    /api/profiles/clubs/{userId}          → Update club profile
//GET    /api/profiles/clubs/search?query=...  → Search clubs
//GET    /api/profiles/clubs/category/{cat}    → Filter by category
//GET    /api/profiles/clubs/department/{id}   → Filter by department
//GET    /api/profiles/clubs/fts?query=...     → Full text search
//GET    /api/profiles/clubs/categories        → Get all categories
//GET    /api/profiles/clubs/open              → Get open clubs


//Big Picture Flow
//
//
//Browser/App sends HTTP request
//        ↓
//Spring Security checks @PreAuthorize
//        ↓
//Controller method runs
//        ↓
//SecurityUtils gets current user (if needed)
//        ↓
//Controller calls Service
//        ↓
//Service does business logic
//        ↓
//Service returns DTO
//        ↓
//Controller wraps in ApiResponse
//        ↓
//ResponseEntity sends HTTP 200 + JSON
//        ↓
//Browser/App receives response