package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.project.ProjectMember;
import com.spl2.uniconnect.dto.response.project.TeamMemberResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ProjectMemberMapper {

    private final UserMapper userMapper;

    public TeamMemberResponse toResponse(ProjectMember projectMember) {
        if (projectMember == null) {
            return null;
        }

        return TeamMemberResponse.builder()
                .memberId(projectMember.getMemberId())
                .user(userMapper.toUserResponse(projectMember.getUser()))  // ✅ Use toUserResponse
                .role(projectMember.getRole())
                .joinedAt(projectMember.getJoinedAt())
                .build();
    }
}