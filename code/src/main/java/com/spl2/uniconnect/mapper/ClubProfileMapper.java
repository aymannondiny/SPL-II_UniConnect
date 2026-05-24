package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.user.ClubProfile;
import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.response.user.ClubProfileResponse;
import org.springframework.stereotype.Component;

@Component
public class ClubProfileMapper {

    // =====================================================
    // Entity → Response DTO
    // =====================================================

    public ClubProfileResponse toResponse(ClubProfile clubProfile) {
        if (clubProfile == null) return null;

        return ClubProfileResponse.builder()
                // IDs
                .clubId(clubProfile.getClubId())
                .userId(clubProfile.getUser().getUserId())

                // User info (from User entity)
                .fullName(clubProfile.getUser().getFullName())
                .profilePhoto(clubProfile.getUser().getProfilePhoto())

                // Required club fields
                .clubName(clubProfile.getClubName())
                .description(clubProfile.getDescription())
                .category(clubProfile.getCategory())

                // Optional club fields
                .foundedYear(clubProfile.getFoundedYear())
                .meetingSchedule(clubProfile.getMeetingSchedule())
                .contactEmail(clubProfile.getContactEmail())
                .websiteUrl(clubProfile.getWebsiteUrl())
                .clubLogo(clubProfile.getClubLogo())

                // Department (if exists)
                .departmentId(clubProfile.getDepartment() != null ?
                        clubProfile.getDepartment().getDepartmentId() : null)
                .departmentName(clubProfile.getDepartment() != null ?
                        clubProfile.getDepartment().getDepartmentName() : null)

                // Metadata
                .createdAt(clubProfile.getCreatedAt())

                .build();
    }

    // =====================================================
    // Request DTO → Entity (for updates)
    // =====================================================

    public void updateEntityFromRequest(UpdateClubProfileRequest request,
                                        ClubProfile clubProfile) {
        if (request == null || clubProfile == null) return;

        // Only update fields that are not null in request
        if (request.getClubName() != null) {
            clubProfile.setClubName(request.getClubName());
        }
        if (request.getDescription() != null) {
            clubProfile.setDescription(request.getDescription());
        }
        if (request.getCategory() != null) {
            clubProfile.setCategory(request.getCategory());
        }
        if (request.getFoundedYear() != null) {
            clubProfile.setFoundedYear(request.getFoundedYear());
        }
        if (request.getMeetingSchedule() != null) {
            clubProfile.setMeetingSchedule(request.getMeetingSchedule());
        }
        if (request.getContactEmail() != null) {
            clubProfile.setContactEmail(request.getContactEmail());
        }
        if (request.getWebsiteUrl() != null) {
            clubProfile.setWebsiteUrl(request.getWebsiteUrl());
        }
        if (request.getClubLogo() != null) {
            clubProfile.setClubLogo(request.getClubLogo());
        }
    }
}