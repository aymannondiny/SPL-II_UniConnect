package com.spl2.uniconnect.dto.response.project;

import com.spl2.uniconnect.dto.response.user.UserResponse;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeamMemberResponse {

    private Long memberId;

    private UserResponse user;

    private String role;  // "Creator", "Member"

    private LocalDateTime joinedAt;
}