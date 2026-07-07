package com.spl2.uniconnect.dto.request.career;

import com.spl2.uniconnect.domain.career.JobType;
import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateJobRequest {

    @NotBlank(message = "Job title is required")
    @Size(max = 255)
    private String title;

    @NotBlank(message = "Company name is required")
    @Size(max = 255)
    private String companyName;

    @NotNull(message = "Job type is required")
    private JobType jobType;

    @NotBlank(message = "Location is required")
    private String location;

    @NotBlank(message = "Description is required")
    private String description;

    private String requirements;

    private String applicationLink;

    @Email(message = "Invalid email format")
    private String applicationEmail;

    @Future(message = "Deadline must be in the future")
    private LocalDate applicationDeadline;

    @Size(max = 100)
    private String salaryRange;
}