package com.spl2.uniconnect.dto.request.project;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectUpdateRequest {

    @Size(min = 5, max = 200, message = "Title must be between 5 and 200 characters")
    private String title;

    @Size(min = 20, max = 5000, message = "Description must be between 20 and 5000 characters")
    private String description;

    @Min(value = 1, message = "At least 1 teammate needed")
    @Max(value = 10, message = "Maximum 10 teammates allowed")
    private Integer teammatesNeeded;

    @Size(max = 100, message = "Course name cannot exceed 100 characters")
    private String courseName;

    @FutureOrPresent(message = "Application deadline must be today or in the future")
    private LocalDate applicationDeadline;

    @Size(max = 100, message = "Project duration cannot exceed 100 characters")
    private String projectDuration;
}