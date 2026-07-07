package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectSkill;
import com.spl2.uniconnect.dto.response.project.ProjectResponse;
import com.spl2.uniconnect.dto.response.project.ProjectSkillResponse;
import com.spl2.uniconnect.repository.project.ProjectApplicationRepository;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.project.ProjectSkillRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
@RequiredArgsConstructor
public class ProjectMapper {

    private final ProjectSkillRepository projectSkillRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final ProjectApplicationRepository projectApplicationRepository;
    private final UserMapper userMapper;

    public ProjectResponse toResponse(Project project) {
        if (project == null) {
            return null;
        }

        Long currentUserId = null;
        try {
            currentUserId = SecurityUtils.getCurrentUserId();
        } catch (Exception e) {
            // Not authenticated
        }

        // Get skills
        List<ProjectSkill> requiredSkills = projectSkillRepository.findRequiredSkillsByProject(project.getProjectId());
        List<ProjectSkill> optionalSkills = projectSkillRepository.findOptionalSkillsByProject(project.getProjectId());

        // Get team size
        long teamSize = projectMemberRepository.countByProjectProjectId(project.getProjectId());

        // Get pending applications count
        long pendingAppsCount = projectApplicationRepository.countPendingByProject(project.getProjectId());

        // Check if user has applied
        Boolean userHasApplied = null;
        String userApplicationStatus = null;
        if (currentUserId != null) {
            userHasApplied = projectApplicationRepository.hasUserAppliedToProject(
                    project.getProjectId(),
                    currentUserId
            );
            if (userHasApplied) {
                userApplicationStatus = projectApplicationRepository
                        .findByProjectProjectIdAndApplicantUserId(project.getProjectId(), currentUserId)
                        .map(app -> app.getStatus().name())
                        .orElse(null);
            }
        }

        return ProjectResponse.builder()
                .id(project.getProjectId())
                .title(project.getTitle())
                .description(project.getDescription())
                .teammatesNeeded(project.getTeammatesNeeded())
                .courseName(project.getCourseName())
                .applicationDeadline(project.getApplicationDeadline())
                .projectDuration(project.getProjectDuration())
                .status(project.getStatus().name())
                .creator(userMapper.toUserResponse(project.getCreator()))  // ✅ Use toUserResponse
                .currentTeamSize(teamSize)
                .requiredSkills(requiredSkills.stream()
                        .map(this::toSkillResponse)
                        .collect(Collectors.toList()))
                .optionalSkills(optionalSkills.stream()
                        .map(this::toSkillResponse)
                        .collect(Collectors.toList()))
                .pendingApplicationCount(pendingAppsCount)
                .userHasApplied(userHasApplied)
                .userApplicationStatus(userApplicationStatus)
                .createdAt(project.getCreatedAt())
                .updatedAt(project.getUpdatedAt())
                .build();
    }

    private ProjectSkillResponse toSkillResponse(ProjectSkill projectSkill) {
        return ProjectSkillResponse.builder()
                .skillId(projectSkill.getSkill().getSkillId())
                .skillName(projectSkill.getSkill().getSkillName())
                .category(projectSkill.getSkill().getCategory())
                .isRequired(projectSkill.getIsRequired())
                .build();
    }
}