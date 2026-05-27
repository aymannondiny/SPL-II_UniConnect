package com.spl2.uniconnect.dto.request.user;

import com.spl2.uniconnect.validation.PastOrPresentYear;
import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateAlumniProfileRequest {

    // Required fields
    @NotNull(message = "Graduation year is required")
    @PastOrPresentYear(
            minYearsBack = 100,
            message = "Graduation year cannot be in the future"
    )
    private Integer graduationYear;

    @NotNull(message = "Programme ID is required")
    private Long programmeId;

    @NotNull(message = "Degree level ID is required")
    private Long degreeLevelId;

    // Optional fields
    @Size(max = 255, message = "Current company cannot exceed 255 characters")
    private String currentCompany;

    @Size(max = 255, message = "Current position cannot exceed 255 characters")
    private String currentPosition;

    @Size(max = 100, message = "Industry cannot exceed 100 characters")
    private String industry;

    @Size(max = 5000, message = "Career background cannot exceed 5000 characters")
    private String careerBackground;

    @Pattern(
            regexp = "^(https?://)?(www\\.)?linkedin\\.com/.*$|^$",
            message = "Invalid LinkedIn URL format"
    )
    @Size(max = 500, message = "LinkedIn URL cannot exceed 500 characters")
    private String linkedinUrl;

    @Size(max = 500, message = "Profile photo URL cannot exceed 500 characters")
    private String profilePhoto;
}