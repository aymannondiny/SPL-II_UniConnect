package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record PublicationAuditResponse(Long id, Long announcementId, Long eventId, Long actorUserId, Long actorAssignmentId,
        String action, String reason, String beforeSnapshot, String afterSnapshot, LocalDateTime createdAt) {}
