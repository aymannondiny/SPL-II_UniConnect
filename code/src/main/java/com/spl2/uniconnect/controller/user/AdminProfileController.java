package com.spl2.uniconnect.controller.user;

import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.user.AdminProfileResponse;
import com.spl2.uniconnect.exception.UnauthorizedException;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.user.AdminProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/profiles")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Admin Profile", description = "Admin Profile Management APIs")
public class AdminProfileController {

    private final AdminProfileService adminProfileService;

    // =====================================================
    // GET ENDPOINTS
    // =====================================================

    /**
     * Get admin profile by user ID
     * GET /api/profiles/admins/{userId}
     */
    @GetMapping("/admins/{userId}")
    @Operation(
            summary = "Get admin profile",
            description = "Get admin profile by user ID - FR-2.6"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<AdminProfileResponse>> getAdminProfile(
            @Parameter(description = "User ID of the admin")
            @PathVariable Long userId) {

        log.info("GET /api/profiles/admins/{}", userId);

        AdminProfileResponse response = adminProfileService
                .getAdminProfileByUserId(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Admin profile retrieved successfully", response)
        );
    }

    /**
     * Get MY admin profile
     * GET /api/profiles/admins/me
     */
    @GetMapping("/admins/me")
    @Operation(
            summary = "Get my admin profile",
            description = "Get the authenticated admin's own profile"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<AdminProfileResponse>> getMyAdminProfile() {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        log.info("GET /api/profiles/admins/me - userId: {}", currentUserId);

        AdminProfileResponse response = adminProfileService
                .getAdminProfileByUserId(currentUserId);

        return ResponseEntity.ok(
                ApiResponse.success("Admin profile retrieved successfully", response)
        );
    }

    /**
     * Get all admin profiles
     * GET /api/profiles/admins
     */
    @GetMapping("/admins")
    @Operation(
            summary = "Get all admins",
            description = "Get all admin profiles - System Admin only"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminProfileResponse>>> getAllAdmins() {

        log.info("GET /api/profiles/admins");

        List<AdminProfileResponse> admins = adminProfileService.getAllAdmins();

        return ResponseEntity.ok(
                ApiResponse.success("Admin profiles retrieved successfully", admins)
        );
    }

    /**
     * Get admins by role
     * GET /api/profiles/admins/role/{role}
     */
    @GetMapping("/admins/role/{role}")
    @Operation(
            summary = "Get admins by role",
            description = "Get all admins with a specific role"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<AdminProfileResponse>>> getAdminsByRole(
            @Parameter(description = "Admin role")
            @PathVariable String role) {

        log.info("GET /api/profiles/admins/role/{}", role);

        List<AdminProfileResponse> admins = adminProfileService.getAdminsByRole(role);

        return ResponseEntity.ok(
                ApiResponse.success("Admin profiles retrieved successfully", admins)
        );
    }

    /**
     * Get all admin roles
     * GET /api/profiles/admins/roles
     */
    @GetMapping("/admins/roles")
    @Operation(
            summary = "Get all admin roles",
            description = "Get all distinct admin roles"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<List<String>>> getAllAdminRoles() {

        log.info("GET /api/profiles/admins/roles");

        List<String> roles = adminProfileService.getAllAdminRoles();

        return ResponseEntity.ok(
                ApiResponse.success("Admin roles retrieved successfully", roles)
        );
    }

    // =====================================================
    // UPDATE ENDPOINTS
    // =====================================================

    /**
     * Update admin profile
     * PUT /api/profiles/admins/{userId}
     * FR-2.5: Edit Profile
     */
    @PutMapping("/admins/{userId}")
    @Operation(
            summary = "Update admin profile",
            description = "Update admin profile - FR-2.5"
    )
    @PreAuthorize("hasRole('SYSTEM_ADMIN')")
    public ResponseEntity<ApiResponse<AdminProfileResponse>> updateAdminProfile(
            @Parameter(description = "User ID of the admin")
            @PathVariable Long userId,
            @Valid @RequestBody UpdateAdminProfileRequest request) {

        Long currentUserId = SecurityUtils.getCurrentUserId();

        if (currentUserId == null) {
            throw new UnauthorizedException("User is not authenticated");
        }

        // Check if current user is system admin
        boolean isSystemAdmin = SecurityUtils.hasRole("SYSTEM_ADMIN");

        log.info("PUT /api/profiles/admins/{} - by userId: {}", userId, currentUserId);

        AdminProfileResponse response = adminProfileService
                .updateAdminProfile(userId, request, currentUserId, isSystemAdmin);

        return ResponseEntity.ok(
                ApiResponse.success("Admin profile updated successfully", response)
        );
    }
}