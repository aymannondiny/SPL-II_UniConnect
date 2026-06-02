package com.spl2.uniconnect.dto.request.project;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectCreateRequest {

    @NotBlank(message = "Project title is required")
    @Size(min = 5, max = 200, message = "Title must be between 5 and 200 characters")
    private String title;

    @NotBlank(message = "Project description is required")
    @Size(min = 20, max = 5000, message = "Description must be between 20 and 5000 characters")
    private String description;

    @NotNull(message = "Number of teammates needed is required")
    @Min(value = 1, message = "At least 1 teammate needed")
    @Max(value = 10, message = "Maximum 10 teammates allowed")
    private Integer teammatesNeeded;

    @Size(max = 100, message = "Course name cannot exceed 100 characters")
    private String courseName;

    @FutureOrPresent(message = "Application deadline must be today or in the future")
    private LocalDate applicationDeadline;

    @Size(max = 100, message = "Project duration cannot exceed 100 characters")
    private String projectDuration;

    @NotEmpty(message = "At least one required skill is needed")
    private List<String> requiredSkills;  // Skill names

    private List<String> optionalSkills;  // Skill names (optional)

    @Size(max = 5, message = "Maximum 5 tags allowed")
    private List<String> tags;  // Tag names
}