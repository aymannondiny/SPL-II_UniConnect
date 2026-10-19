package com.uniconnect.career.dto;

import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.WorkMode;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;

public record CareerPostRequest(
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 200) String companyName,
        @NotBlank @Size(max = 5000) String description,
        @NotBlank @Size(max = 5000) String qualifications,
        @Size(max = 200) String location,
        @NotNull EmploymentType employmentType,
        @NotNull WorkMode workMode,
        @Size(max = 200) String salaryRange,
        @Size(max = 2048) String applicationUrl,
        @Email @Size(max = 320) String applicationEmail,
        @NotNull LocalDate applicationDeadline,
        @NotNull @Size(max = 50) List<@Valid CareerSkillRequest> skills
) {}
