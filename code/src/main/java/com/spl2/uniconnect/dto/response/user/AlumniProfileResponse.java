package com.spl2.uniconnect.dto.response.user;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class AlumniProfileResponse {

    // IDs
    private Long alumniId;
    private Long userId;

    // From User entity
    private String fullName;
    private String email;
    private String profilePhoto;

    // Required alumni fields
    private Integer graduationYear;

    // Programme info
    private Long programmeId;
    private String programmeName;
    private String programmeCode;

    // Degree level info
    private Long degreeLevelId;
    private String degreeName;

    // Department info (from programme)
    private Long departmentId;
    private String departmentName;

    // Optional career fields
    private String currentCompany;
    private String currentPosition;
    private String industry;
    private String careerBackground;
    private String linkedinUrl;

    // Metadata
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}