package com.uniconnect.project.dto;

import com.uniconnect.project.domain.ProjectApplicationStatus;
import java.time.LocalDateTime;

public record ProjectApplicationResponse(long id, long projectId, long applicantUserId,
        String applicantDisplayName, String message, ProjectApplicationStatus status,
        LocalDateTime appliedAt, LocalDateTime respondedAt) {}
