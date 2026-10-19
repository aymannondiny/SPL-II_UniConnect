package com.uniconnect.career.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CareerSkillRequest(
        @NotBlank @Size(max = 60) String name,
        boolean required
) {}
