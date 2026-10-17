package com.uniconnect.club.dto;
import java.time.LocalDateTime;
public record ClubAuditResponse(Long id, Long clubId, Long actorId, Long actorAssignmentId,
        Long targetAssignmentId, String action, String reason, LocalDateTime createdAt,
        com.uniconnect.club.domain.ClubStatus previousState, com.uniconnect.club.domain.ClubStatus newState) {}
