package com.spl2.uniconnect.dto.response.user;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class StudentProfileResponse {

    // IDs
    private Long studentId;
    private Long userId;

    // From User entity
    private String fullName;
    private String email;
    private String profilePhoto;

    // Required student fields
    private Integer yearOfStudy;

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

    // Optional fields
    private String bio;
    private Integer expectedGraduationYear;
    private Boolean lookingForTeammates;
    private Boolean openToMentorship;

    // Metadata
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}