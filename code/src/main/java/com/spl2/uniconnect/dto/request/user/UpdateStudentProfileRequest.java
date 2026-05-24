package com.spl2.uniconnect.dto.request.user;

import com.spl2.uniconnect.validation.FutureOrPresentYear;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateStudentProfileRequest {

    // Required fields
    @NotNull(message = "Year of study is required")
    @Min(value = 1, message = "Year of study must be at least 1")
    @Max(value = 7, message = "Year of study must be at most 7")
    private Integer yearOfStudy;

    @NotNull(message = "Programme ID is required")
    private Long programmeId;

    @NotNull(message = "Degree level ID is required")
    private Long degreeLevelId;

    // Optional fields
    @Size(max = 5000, message = "Bio cannot exceed 5000 characters")
    private String bio;

    // ✅ Dynamic year validation - no hardcoded years!
    @FutureOrPresentYear(
            maxYearsAhead = 8,
            message = "Graduation year must be current year or in the future"
    )
    private Integer expectedGraduationYear;

    private Boolean lookingForTeammates;

    private Boolean openToMentorship;

    @Size(max = 500, message = "Profile photo URL cannot exceed 500 characters")
    private String profilePhoto;
}