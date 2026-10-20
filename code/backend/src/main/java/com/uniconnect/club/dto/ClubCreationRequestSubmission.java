package com.uniconnect.club.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ClubCreationRequestSubmission(@NotBlank @Size(max = 150) String clubName,
        @NotBlank @Size(max = 100) String category,
        @NotBlank @Size(max = 5000) String description,
        @Size(max = 2048) String logoUrl,
        @Email @Size(max = 320) String contactEmail) {}
