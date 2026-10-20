package com.uniconnect.project.dto;

import com.uniconnect.project.domain.*;
import java.time.*;
import java.util.List;

public record ProjectResponse(
        long id, Long creatorUserId, String creatorDisplayName,
        Long creatorDepartmentId, String creatorDepartmentCode, String creatorDepartmentName,
        String title, String description, int teamSizeLimit, String duration, String courseName,
        LocalDate applicationDeadline, ProjectStatus status, ProjectAvailability availability,
        long membershipCount, long vacancies, boolean full, boolean canApply,
        ProjectApplicationStatus currentApplicationStatus,
        List<ProjectSkillResponse> skills, LocalDateTime createdAt, LocalDateTime updatedAt,
        LocalDateTime closedAt
) {}
