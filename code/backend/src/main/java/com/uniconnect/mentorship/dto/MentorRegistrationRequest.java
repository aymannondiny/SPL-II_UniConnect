package com.uniconnect.mentorship.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import java.util.List;

public record MentorRegistrationRequest(
        @NotBlank(message = "Mentoring bio is required")
        @Size(min = 10, max = 5000, message = "Mentoring bio must be between 10 and 5000 characters")
        String mentoringBio,

        @NotEmpty(message = "At least one expertise area is required")
        List<@Valid ExpertiseRequest> expertise
) {}
