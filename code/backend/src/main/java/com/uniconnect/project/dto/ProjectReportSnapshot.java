package com.uniconnect.project.dto;

import com.uniconnect.project.domain.ProjectAvailability;
import com.uniconnect.project.domain.ProjectStatus;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/** Immutable, reporter-visible project detail retained by Content Reporting. */
public record ProjectReportSnapshot(
        long id,
        Long creatorUserId,
        String creatorDisplayName,
        String title,
        String description,
        int teamSizeLimit,
        String duration,
        String courseName,
        LocalDate applicationDeadline,
        ProjectStatus status,
        ProjectAvailability availability,
        List<ProjectSkillResponse> skills,
        LocalDateTime createdAt,
        LocalDateTime updatedAt,
        LocalDateTime closedAt
) {}
