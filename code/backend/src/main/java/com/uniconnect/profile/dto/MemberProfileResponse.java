package com.uniconnect.profile.dto;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.uniconnect.connection.dto.ConnectionSummary;
import com.uniconnect.profile.dto.AcademicCatalogResponse.*;
import com.uniconnect.shared.security.PlatformRole;
import java.util.List;

/** Separate public contract: email and student number have no representation here. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record MemberProfileResponse(Long userId, String fullName, PlatformRole platformRole,
        String profilePhotoUrl, DepartmentOption department, ProgrammeOption programme,
        ConnectionSummary connection, boolean detailsVisible, Details details) {
    public record Details(DegreeOption degree, String bio, List<String> skills, List<String> interests,
            List<String> sharedSkills, List<String> sharedInterests, StudentDetails student, ProfileResponse.AlumniDetails alumni) {}
    public record StudentDetails(Integer yearOfStudy, Integer expectedGraduationYear,
            Boolean projectAvailability, Boolean mentorshipAvailability) {}
}
