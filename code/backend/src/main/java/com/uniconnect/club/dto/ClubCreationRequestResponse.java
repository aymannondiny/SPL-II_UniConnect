package com.uniconnect.club.dto;

import com.uniconnect.club.domain.ClubCreationRequestStatus;
import java.time.LocalDateTime;

public record ClubCreationRequestResponse(Long id, Long requesterUserId, String requesterName,
        String clubName, String category, String description, String logoUrl, String contactEmail,
        ClubCreationRequestStatus status, LocalDateTime createdAt, LocalDateTime decidedAt,
        Long decidedBy, String rejectionReason, Long clubId) {}
