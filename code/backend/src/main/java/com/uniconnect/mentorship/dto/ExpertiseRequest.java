package com.uniconnect.mentorship.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ExpertiseRequest(
        @NotBlank(message = "Topic is required")
        @Size(min = 2, max = 100, message = "Topic must be between 2 and 100 characters")
        String topic,

        @Size(max = 1000, message = "Description must be at most 1000 characters")
        String description
) {}
