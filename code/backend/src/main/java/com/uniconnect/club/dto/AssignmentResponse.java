package com.uniconnect.club.dto;
import com.uniconnect.club.domain.ClubRole;
import java.time.LocalDateTime;
public record AssignmentResponse(Long id, Long clubId, Long userId, String fullName, ClubRole role,
        boolean current, Long assignedBy, LocalDateTime assignedAt, Long revokedBy, LocalDateTime revokedAt) {}
