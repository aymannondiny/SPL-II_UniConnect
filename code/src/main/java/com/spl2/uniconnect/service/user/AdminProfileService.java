package com.spl2.uniconnect.service.user;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.response.user.AdminProfileResponse;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.AdminProfileMapper;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminProfileService {

    private final AdminProfileRepository adminProfileRepository;
    private final UserRepository userRepository;
    private final AdminProfileMapper adminProfileMapper;

    // =====================================================
    // GET ADMIN PROFILE
    // =====================================================

    /**
     * Get admin profile by user ID
     */
    @Transactional(readOnly = true)
    public AdminProfileResponse getAdminProfileByUserId(Long userId) {
        log.info("Fetching admin profile for userId: {}", userId);

        AdminProfile adminProfile = adminProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Admin profile not found for userId: " + userId));

        return adminProfileMapper.toResponse(adminProfile);
    }

    /**
     * Get admin profile by admin ID
     */
    @Transactional(readOnly = true)
    public AdminProfileResponse getAdminProfileByAdminId(Long adminId) {
        log.info("Fetching admin profile for adminId: {}", adminId);

        AdminProfile adminProfile = adminProfileRepository
                .findById(adminId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Admin profile not found for adminId: " + adminId));

        return adminProfileMapper.toResponse(adminProfile);
    }

    /**
     * Get all admin profiles
     * Only accessible by System Admin
     */
    @Transactional(readOnly = true)
    public List<AdminProfileResponse> getAllAdmins() {
        log.info("Fetching all admin profiles");

        return adminProfileRepository.findAll()
                .stream()
                .map(adminProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get admins by role
     */
    @Transactional(readOnly = true)
    public List<AdminProfileResponse> getAdminsByRole(String role) {
        log.info("Fetching admins with role: {}", role);

        return adminProfileRepository.findByAdminRole(role)
                .stream()
                .map(adminProfileMapper::toResponse)
                .collect(Collectors.toList());
    }

    // =====================================================
    // UPDATE ADMIN PROFILE
    // =====================================================

    /**
     * Update admin profile
     * FR-2.5: Edit Profile
     */
    @Transactional
    public AdminProfileResponse updateAdminProfile(Long userId,
                                                   UpdateAdminProfileRequest request,
                                                   Long currentUserId,
                                                   boolean isSystemAdmin) {
        log.info("Updating admin profile for userId: {}", userId);

        // 1. Check authorization
        // Only owner OR system admin can update
        if (!userId.equals(currentUserId) && !isSystemAdmin) {
            throw new ForbiddenException(
                    "You are not authorized to update this profile");
        }

        // 2. Find existing admin profile
        AdminProfile adminProfile = adminProfileRepository
                .findByUserUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Admin profile not found for userId: " + userId));

        // 3. Handle profile photo update (stored on User entity)
        if (request.getProfilePhoto() != null) {
            User user = adminProfile.getUser();
            user.setProfilePhoto(request.getProfilePhoto());
            userRepository.save(user);
        }

        // 4. Update remaining fields
        adminProfileMapper.updateEntityFromRequest(request, adminProfile);

        // 5. Save and return
        AdminProfile savedProfile = adminProfileRepository.save(adminProfile);
        log.info("Admin profile updated successfully for userId: {}", userId);

        return adminProfileMapper.toResponse(savedProfile);
    }

    // =====================================================
    // ANALYTICS
    // =====================================================

    /**
     * Get all distinct admin roles
     */
    @Transactional(readOnly = true)
    public List<String> getAllAdminRoles() {
        log.info("Fetching all distinct admin roles");
        return adminProfileRepository.findAllDistinctRoles();
    }
}