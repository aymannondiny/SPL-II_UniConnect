package com.uniconnect.profile.dto;

import jakarta.validation.constraints.*;
import java.util.List;

public record StudentProfileRequest(@NotBlank @Size(max = 100) String fullName,
        @NotNull @Positive Long programmeDegreeId,
        @Size(max = 2000) String bio,
        @Size(max = 2048) String profilePhotoUrl,
        @NotNull @Size(max = 30) List<@NotBlank @Size(max = 60) String> skills,
        @NotNull @Size(max = 30) List<@NotBlank @Size(max = 60) String> interests,
        @NotBlank @Pattern(regexp = "[A-Za-z0-9-]{1,40}") String studentNumber,
        @NotNull @Min(1) @Max(20) Integer yearOfStudy,
        @Min(1900) @Max(2200) Integer expectedGraduationYear,
        @NotNull Boolean projectAvailability, @NotNull Boolean mentorshipAvailability) {
    @Override public String toString() { return "StudentProfileRequest[REDACTED]"; }
}
