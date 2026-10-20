package com.uniconnect.project.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.util.List;

public record ProjectRequest(
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 5000) String description,
        @Min(2) @Max(100) int teamSizeLimit,
        @Size(max = 200) String duration,
        @Size(max = 200) String courseName,
        @NotNull LocalDate applicationDeadline,
        @NotNull @Size(min = 1, max = 50) List<@Valid ProjectSkillRequest> skills
) {}
