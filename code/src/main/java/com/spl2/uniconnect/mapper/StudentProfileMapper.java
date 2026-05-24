package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.StudentProfile;
import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.dto.response.user.StudentProfileResponse;
import org.springframework.stereotype.Component;

@Component
public class StudentProfileMapper {

    // =====================================================
    // Entity → Response DTO
    // =====================================================

    public StudentProfileResponse toResponse(StudentProfile studentProfile) {
        if (studentProfile == null) return null;

        Programme programme = studentProfile.getProgramme();
        DegreeLevel degreeLevel = studentProfile.getDegreeLevel();

        return StudentProfileResponse.builder()
                // IDs
                .studentId(studentProfile.getStudentId())
                .userId(studentProfile.getUser().getUserId())

                // From User entity
                .fullName(studentProfile.getUser().getFullName())
                .email(studentProfile.getUser().getEmail())
                .profilePhoto(studentProfile.getUser().getProfilePhoto())

                // Required student fields
                .yearOfStudy(studentProfile.getYearOfStudy())

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

                // Optional fields
                .bio(studentProfile.getBio())
                .expectedGraduationYear(studentProfile.getExpectedGraduationYear())
                .lookingForTeammates(studentProfile.getLookingForTeammates())
                .openToMentorship(studentProfile.getOpenToMentorship())

                // Metadata
                .createdAt(studentProfile.getCreatedAt())
                .updatedAt(studentProfile.getUpdatedAt())

                .build();
    }

    // =====================================================
    // Request DTO → Entity (for updates)
    // =====================================================

    public void updateEntityFromRequest(UpdateStudentProfileRequest request,
                                        StudentProfile studentProfile) {
        if (request == null || studentProfile == null) return;

        // Only update fields that are not null
        if (request.getYearOfStudy() != null) {
            studentProfile.setYearOfStudy(request.getYearOfStudy());
        }
        if (request.getBio() != null) {
            studentProfile.setBio(request.getBio());
        }
        if (request.getExpectedGraduationYear() != null) {
            studentProfile.setExpectedGraduationYear(request.getExpectedGraduationYear());
        }
        if (request.getLookingForTeammates() != null) {
            studentProfile.setLookingForTeammates(request.getLookingForTeammates());
        }
        if (request.getOpenToMentorship() != null) {
            studentProfile.setOpenToMentorship(request.getOpenToMentorship());
        }
        // Note: profilePhoto is updated on User entity, not StudentProfile
        // Note: programme and degreeLevel are handled in service layer
    }
}