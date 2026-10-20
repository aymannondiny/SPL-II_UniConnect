package com.uniconnect.club.dto;
import jakarta.validation.constraints.*;
import com.uniconnect.shared.security.ContextType;
import java.util.List;
public record CreateClubRequest(@NotBlank @Size(max=150) String clubName, @NotBlank @Size(max=100) String category,
        @NotBlank @Size(max=5000) String description, @Size(max=2048) String logoUrl,
        @Email @Size(max=320) String contactEmail, @Positive Long administratorUserId,
        @Size(max=25) List<@NotNull @Positive Long> administratorUserIds) {
    public CreateClubRequest(String clubName, String category, String description, String logoUrl,
            String contactEmail, Long administratorUserId) {
        this(clubName, category, description, logoUrl, contactEmail, administratorUserId, null);
    }
    public List<Long> administratorIds() {
        if (administratorUserIds != null && !administratorUserIds.isEmpty()) return administratorUserIds;
        return administratorUserId == null ? List.of() : List.of(administratorUserId);
    }
}
