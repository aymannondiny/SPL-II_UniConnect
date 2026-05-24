package com.spl2.uniconnect.controller.user;

import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.common.PageResponse;
import com.spl2.uniconnect.dto.response.user.StudentProfileResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.user.StudentProfileService;
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
@Tag(name = "Student Profile", description = "Student Profile Management APIs")
public class StudentProfileController {

    private final StudentProfileService studentProfileService;

    // =====================================================
    // GET ENDPOINTS
    // =====================================================

    /**
     * Get student profile by user ID
     * GET /api/profiles/students/{userId}
     */
    @GetMapping("/students/{userId}")
    @Operation(
            summary = "Get student profile",
            description = "Get student profile by user ID"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> getStudentProfile(
            @Parameter(description = "User ID of the student")
            @PathVariable Long userId) {

        log.info("GET /api/profiles/students/{}", userId);

        StudentProfileResponse response = studentProfileService
                .getStudentProfileByUserId(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Student profile retrieved successfully", response)
        );
    }

    /**
     * Get MY student profile
     * GET /api/profiles/students/me
     */
    @GetMapping("/students/me")
    @Operation(
            summary = "Get my student profile",
            description = "Get the authenticated student's own profile"
    )
    @PreAuthorize("hasRole('STUDENT')")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> getMyStudentProfile() {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("GET /api/profiles/students/me - userId: {}", currentUserId);

        StudentProfileResponse response = studentProfileService
                .getStudentProfileByUserId(currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Student profile retrieved successfully", response)
        );
    }

    // =====================================================
    // UPDATE ENDPOINTS
    // =====================================================

    /**
     * Update student profile
     * PUT /api/profiles/students/{userId}
     */
    @PutMapping("/students/{userId}")
    @Operation(
            summary = "Update student profile",
            description = "Update student profile"
    )
    @PreAuthorize("hasRole('STUDENT') or hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<StudentProfileResponse>> updateStudentProfile(
            @Parameter(description = "User ID of the student")
            @PathVariable Long userId,
            @Valid @RequestBody UpdateStudentProfileRequest request) {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("PUT /api/profiles/students/{} - by userId: {}", userId, currentUserId);

        StudentProfileResponse response = studentProfileService
                .updateStudentProfile(userId, request, currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Student profile updated successfully", response)
        );
    }

    // =====================================================
    // SEARCH & FILTER ENDPOINTS
    // =====================================================

    /**
     * Search students
     * GET /api/profiles/students/search?query=john
     */
    @GetMapping("/students/search")
    @Operation(
            summary = "Search students",
            description = "Search students by name or bio with pagination"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> searchStudents(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "asc") String sortDir) {

        log.info("GET /api/profiles/students/search - query: {}", query);

        Sort sort = sortDir.equalsIgnoreCase("desc")
                ? Sort.by("user.fullName").descending()
                : Sort.by("user.fullName").ascending();

        Pageable pageable = PageRequest.of(page, size, sort);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .searchStudents(query, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Get students by programme
     * GET /api/profiles/students/programme/{programmeId}
     */
    @GetMapping("/students/programme/{programmeId}")
    @Operation(
            summary = "Get students by programme",
            description = "Get all students in a specific programme"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> getStudentsByProgramme(
            @PathVariable Long programmeId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/students/programme/{}", programmeId);

        Pageable pageable = PageRequest.of(page, size);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .getStudentsByProgramme(programmeId, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Get students by year of study
     * GET /api/profiles/students/year/{year}
     */
    @GetMapping("/students/year/{year}")
    @Operation(
            summary = "Get students by year",
            description = "Get all students in a specific year of study"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> getStudentsByYear(
            @PathVariable Integer year,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/students/year/{}", year);

        Pageable pageable = PageRequest.of(page, size);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .getStudentsByYear(year, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Get students looking for teammates
     * GET /api/profiles/students/teammates
     */
    @GetMapping("/students/teammates")
    @Operation(
            summary = "Get students looking for teammates",
            description = "Get all students who are looking for project teammates"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> getStudentsLookingForTeammates(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/students/teammates");

        Pageable pageable = PageRequest.of(page, size);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .getStudentsLookingForTeammates(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Get students open to mentorship
     * GET /api/profiles/students/mentorship
     */
    @GetMapping("/students/mentorship")
    @Operation(
            summary = "Get students open to mentorship",
            description = "Get all students who are open to mentorship"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> getStudentsOpenToMentorship(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/students/mentorship");

        Pageable pageable = PageRequest.of(page, size);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .getStudentsOpenToMentorship(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Get students by department
     * GET /api/profiles/students/department/{departmentId}
     */
    @GetMapping("/students/department/{departmentId}")
    @Operation(
            summary = "Get students by department",
            description = "Get all students in a specific department"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<StudentProfileResponse>>> getStudentsByDepartment(
            @PathVariable Long departmentId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        log.info("GET /api/profiles/students/department/{}", departmentId);

        Pageable pageable = PageRequest.of(page, size);

        Page<StudentProfileResponse> studentPage = studentProfileService
                .getStudentsByDepartment(departmentId, pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully",
                        PageResponse.of(studentPage))
        );
    }

    /**
     * Full text search students
     * GET /api/profiles/students/fts?query=java
     */
    @GetMapping("/students/fts")
    @Operation(
            summary = "Full text search students",
            description = "PostgreSQL full-text search for students"
    )
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<StudentProfileResponse>>> fullTextSearch(
            @RequestParam String query) {

        log.info("GET /api/profiles/students/fts - query: {}", query);

        List<StudentProfileResponse> students = studentProfileService
                .fullTextSearchStudents(query);

        return ResponseEntity.ok(
                ApiResponse.success("Students retrieved successfully", students)
        );
    }
}


//API Endpoints Summary:
//Method	Endpoint	Role
//GET	/api/profiles/students/{userId}	All authenticated
//GET	/api/profiles/students/me	Student only
//PUT	/api/profiles/students/{userId}	Student / System Admin
//GET	/api/profiles/students/search	All authenticated
//GET	/api/profiles/students/programme/{programmeId}	All authenticated
//GET	/api/profiles/students/year/{year}	All authenticated
//GET	/api/profiles/students/teammates	All authenticated
//GET	/api/profiles/students/mentorship	All authenticated
//GET	/api/profiles/students/department/{departmentId}	All authenticated
//GET	/api/profiles/students/fts	All authenticated