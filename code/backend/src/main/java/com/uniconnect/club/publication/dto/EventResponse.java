package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record EventResponse(Long id, Long clubId, String clubName, String category, Long authorUserId, Long authorAssignmentId,
        String title, String description, String location, String registrationUrl, LocalDateTime registrationDeadline,
        LocalDateTime startsAt, LocalDateTime endsAt, EventStatus status, EventTiming timing,
        LocalDateTime publishedAt, LocalDateTime updatedAt, LocalDateTime removedAt) {}
