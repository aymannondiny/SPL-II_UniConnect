package com.spl2.uniconnect.dto.response.project;

import com.spl2.uniconnect.dto.response.user.UserResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProjectResponse {

    private Long id;

    private String title;

    private String description;

    private Integer teammatesNeeded;

    private String courseName;

    private LocalDate applicationDeadline;

    private String projectDuration;

    private String status;  // "Open" or "Closed"

    private UserResponse creator;

    // ✅ Team Info
    private Long currentTeamSize;

    private List<TeamMemberResponse> teamMembers;

    // ✅ Skills
    private List<ProjectSkillResponse> requiredSkills;

    private List<ProjectSkillResponse> optionalSkills;

    // ✅ Tags
    private List<String> tags;

    // ✅ Timestamps
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    // ✅ Application Info
    private Long pendingApplicationCount;

    private Boolean userHasApplied;

    private String userApplicationStatus;  // "Pending", "Accepted", "Rejected", null
}