package com.uniconnect.club.publication.dto;
import com.uniconnect.club.publication.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
public record AnnouncementRequest(@NotBlank @Size(max = 200) String title, @NotBlank @Size(max = 10000) String content,
        @NotNull AnnouncementPriority priority, @NotNull AnnouncementStatus status, LocalDateTime expiresAt) {}
