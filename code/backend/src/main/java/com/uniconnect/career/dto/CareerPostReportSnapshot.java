package com.uniconnect.career.dto;

import com.uniconnect.career.domain.ApplicationChannel;
import com.uniconnect.career.domain.CareerPostAvailability;
import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.WorkMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

/** Immutable, reporter-visible career-post detail retained by Content Reporting. */
public record CareerPostReportSnapshot(
        long id,
        Long authorUserId,
        String authorDisplayName,
        String title,
        String companyName,
        String description,
        String qualifications,
        String location,
        EmploymentType employmentType,
        WorkMode workMode,
        String salaryRange,
        String applicationUrl,
        String applicationEmail,
        LocalDate applicationDeadline,
        CareerPostAvailability status,
        Set<ApplicationChannel> applicationChannels,
        List<CareerSkillResponse> skills,
        LocalDateTime postedAt,
        LocalDateTime updatedAt,
        LocalDateTime closedAt
) {}
