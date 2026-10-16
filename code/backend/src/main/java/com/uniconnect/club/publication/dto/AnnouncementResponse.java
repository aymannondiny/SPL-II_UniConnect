package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record AnnouncementResponse(Long id, Long clubId, String clubName, String category, Long authorUserId, Long authorAssignmentId,
        String title, String content, AnnouncementPriority priority, AnnouncementStatus status,
        LocalDateTime createdAt, LocalDateTime updatedAt, LocalDateTime publishedAt, LocalDateTime expiresAt, LocalDateTime removedAt) {}
