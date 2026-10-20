package com.uniconnect.project.dto;
import com.uniconnect.project.domain.ProjectAuditEvent;
import java.time.LocalDateTime;
public record ProjectAuditResponse(long id, Long actorUserId, Long applicationId,
        ProjectAuditEvent eventType, LocalDateTime occurredAt) {}
