package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.project.ProjectApplication;
import com.spl2.uniconnect.dto.response.project.ApplicationResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class ApplicationMapper {

    private final UserMapper userMapper;

    public ApplicationResponse toResponse(ProjectApplication application) {
        if (application == null) {
            return null;
        }

        return ApplicationResponse.builder()
                .id(application.getApplicationId())
                .projectId(application.getProject().getProjectId())
                .projectTitle(application.getProject().getTitle())
                .applicant(userMapper.toUserResponse(application.getApplicant()))  // ✅ Use toUserResponse
                .message(application.getMessage())
                .status(application.getStatus().name())
                .appliedAt(application.getAppliedAt())
                .respondedAt(application.getRespondedAt())
                .build();
    }
}