package com.spl2.uniconnect.dto.response.user;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ClubProfileResponse {

    // IDs
    private Long clubId;
    private Long userId;

    // From User entity
    private String fullName;
    private String profilePhoto;

    // Required club fields
    private String clubName;
    private String description;
    private String category;

    // Optional club fields
    private Integer foundedYear;
    private String meetingSchedule;
    private String contactEmail;
    private String websiteUrl;
    private String clubLogo;

    // Department info
    private Long departmentId;
    private String departmentName;

    // Metadata
    private LocalDateTime createdAt;
}