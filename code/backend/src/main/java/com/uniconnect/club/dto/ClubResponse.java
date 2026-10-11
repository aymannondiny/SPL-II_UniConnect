package com.uniconnect.club.dto;
import com.uniconnect.club.domain.ClubStatus;
import java.time.LocalDateTime;
public record ClubResponse(Long id, String clubName, String category, String description,
        String logoUrl, String contactEmail, ClubStatus status, LocalDateTime createdAt, LocalDateTime updatedAt) {}
