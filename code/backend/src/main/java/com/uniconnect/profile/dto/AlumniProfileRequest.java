package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;
import java.util.List;

public record AlumniProfileRequest(@NotBlank @Size(max = 100) String fullName,
        @NotNull @Positive Long programmeDegreeId,
        @Size(max = 2000) String bio,
        @Size(max = 2048) String profilePhotoUrl,
        @NotNull @Size(max = 30) List<@NotBlank @Size(max = 60) String> skills,
        @NotNull @Size(max = 30) List<@NotBlank @Size(max = 60) String> interests,
        @NotNull @Min(1900) @Max(2200) Integer graduationYear,
        @Size(max = 150) String currentCompany, @Size(max = 150) String currentPosition,
        @Size(max = 100) String industry, @Size(max = 2000) String careerBackground,
        @Size(max = 2048) String linkedinUrl) {
    @Override public String toString() { return "AlumniProfileRequest[REDACTED]"; }
}
