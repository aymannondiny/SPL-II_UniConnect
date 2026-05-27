package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.user.AdminProfile;
import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.response.user.AdminProfileResponse;
import org.springframework.stereotype.Component;

@Component
public class AdminProfileMapper {

    // =====================================================
    // Entity → Response DTO
    // =====================================================

    public AdminProfileResponse toResponse(AdminProfile adminProfile) {
        if (adminProfile == null) return null;

        return AdminProfileResponse.builder()
                // IDs
                .adminId(adminProfile.getAdminId())
                .userId(adminProfile.getUser().getUserId())

                // From User entity
                .fullName(adminProfile.getUser().getFullName())
                .email(adminProfile.getUser().getEmail())
                .profilePhoto(adminProfile.getUser().getProfilePhoto())

                // Admin specific fields
                .adminRole(adminProfile.getAdminRole())

                // Metadata - from User since AdminProfile has no createdAt
                .createdAt(adminProfile.getUser().getCreatedAt())

                .build();
    }

    // =====================================================
    // Request DTO → Entity (for updates)
    // =====================================================

    public void updateEntityFromRequest(UpdateAdminProfileRequest request,
                                        AdminProfile adminProfile) {
        if (request == null || adminProfile == null) return;

        // Only update fields that are not null
        if (request.getAdminRole() != null) {
            adminProfile.setAdminRole(request.getAdminRole());
        }
        // Note: profilePhoto is updated on User entity
    }
}