package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.AlumniProfile;
import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.response.user.AlumniProfileResponse;
import org.springframework.stereotype.Component;

@Component
public class AlumniProfileMapper {

    // =====================================================
    // Entity → Response DTO
    // =====================================================

    public AlumniProfileResponse toResponse(AlumniProfile alumniProfile) {
        if (alumniProfile == null) return null;

        Programme programme = alumniProfile.getProgramme();
        DegreeLevel degreeLevel = alumniProfile.getDegreeLevel();

        return AlumniProfileResponse.builder()
                // IDs
                .alumniId(alumniProfile.getAlumniId())
                .userId(alumniProfile.getUser().getUserId())

                // From User entity
                .fullName(alumniProfile.getUser().getFullName())
                .email(alumniProfile.getUser().getEmail())
                .profilePhoto(alumniProfile.getUser().getProfilePhoto())

                // Required alumni fields
                .graduationYear(alumniProfile.getGraduationYear())

                // Programme info
                .programmeId(programme != null ? programme.getProgrammeId() : null)
                .programmeName(programme != null ? programme.getProgrammeName() : null)
                .programmeCode(programme != null ? programme.getProgrammeCode() : null)

                // Department info (from programme)
                .departmentId(programme != null && programme.getDepartment() != null ?
                        programme.getDepartment().getDepartmentId() : null)
                .departmentName(programme != null && programme.getDepartment() != null ?
                        programme.getDepartment().getDepartmentName() : null)

                // Degree level info
                .degreeLevelId(degreeLevel != null ? degreeLevel.getDegreeLevelId() : null)
                .degreeName(degreeLevel != null ? degreeLevel.getDegreeName() : null)

                // Optional career fields
                .currentCompany(alumniProfile.getCurrentCompany())
                .currentPosition(alumniProfile.getCurrentPosition())
                .industry(alumniProfile.getIndustry())
                .careerBackground(alumniProfile.getCareerBackground())
                .linkedinUrl(alumniProfile.getLinkedinUrl())

                // Metadata
                .createdAt(alumniProfile.getCreatedAt())
                .updatedAt(alumniProfile.getUpdatedAt())

                .build();
    }

    // =====================================================
    // Request DTO → Entity (for updates)
    // =====================================================

    public void updateEntityFromRequest(UpdateAlumniProfileRequest request,
                                        AlumniProfile alumniProfile) {
        if (request == null || alumniProfile == null) return;

        // Only update fields that are not null
        if (request.getGraduationYear() != null) {
            alumniProfile.setGraduationYear(request.getGraduationYear());
        }
        if (request.getCurrentCompany() != null) {
            alumniProfile.setCurrentCompany(request.getCurrentCompany());
        }
        if (request.getCurrentPosition() != null) {
            alumniProfile.setCurrentPosition(request.getCurrentPosition());
        }
        if (request.getIndustry() != null) {
            alumniProfile.setIndustry(request.getIndustry());
        }
        if (request.getCareerBackground() != null) {
            alumniProfile.setCareerBackground(request.getCareerBackground());
        }
        if (request.getLinkedinUrl() != null) {
            alumniProfile.setLinkedinUrl(request.getLinkedinUrl());
        }
        // Note: profilePhoto is updated on User entity
        // Note: programme and degreeLevel are handled in service layer
    }
}