package com.uniconnect.project.dto;
import com.uniconnect.project.domain.ProjectMemberRole;
import java.time.LocalDateTime;
public record ProjectMembershipResponse(long id, long userId, String displayName,
        ProjectMemberRole role, LocalDateTime joinedAt) {}
