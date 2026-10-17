package com.uniconnect.profile.dto;

import com.uniconnect.shared.security.PlatformRole;
import java.time.LocalDateTime;
import java.util.List;

/** Owner-only representation. Never reuse as a public profile response. */
public record ProfileResponse(Long profileId, Long userId, String fullName, PlatformRole platformRole,
        AcademicCatalogResponse.DepartmentOption department,
        AcademicCatalogResponse.ProgrammeOption programme,
        AcademicCatalogResponse.DegreeOption degree,
        String bio, String profilePhotoUrl, List<String> skills, List<String> interests,
        StudentDetails student, AlumniDetails alumni, LocalDateTime createdAt, LocalDateTime updatedAt) {
    public record StudentDetails(String studentNumber, Integer yearOfStudy, Integer expectedGraduationYear,
            Boolean projectAvailability, Boolean mentorshipAvailability) {}
    public record AlumniDetails(Integer graduationYear, String currentCompany, String currentPosition,
            String industry, String careerBackground, String linkedinUrl) {}
}
