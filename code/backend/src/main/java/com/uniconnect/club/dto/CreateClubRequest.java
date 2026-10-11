package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
public record CreateClubRequest(@NotBlank @Size(max=150) String clubName, @NotBlank @Size(max=100) String category,
        @NotBlank @Size(max=5000) String description, @Size(max=2048) String logoUrl,
        @Email @Size(max=320) String contactEmail, @NotNull @Positive Long administratorUserId) {}
