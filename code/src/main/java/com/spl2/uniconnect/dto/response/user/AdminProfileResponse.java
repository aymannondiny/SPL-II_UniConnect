package com.spl2.uniconnect.dto.response.user;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AdminProfileResponse {

    // IDs
    private Long adminId;
    private Long userId;

    // From User entity
    private String fullName;
    private String email;
    private String profilePhoto;

    // Admin specific fields
    private String adminRole;

    // Metadata
    private LocalDateTime createdAt;
}