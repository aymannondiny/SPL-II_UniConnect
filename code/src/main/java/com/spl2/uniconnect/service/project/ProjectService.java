package com.spl2.uniconnect.service.project;

import com.spl2.uniconnect.domain.project.*;
import com.spl2.uniconnect.domain.skill.Skill;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.project.ProjectCreateRequest;
import com.spl2.uniconnect.dto.request.project.ProjectUpdateRequest;
import com.spl2.uniconnect.dto.response.project.ProjectResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ProjectMapper;
import com.spl2.uniconnect.repository.project.*;
import com.spl2.uniconnect.repository.skill.SkillRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final ProjectApplicationRepository projectApplicationRepository;
    private final ProjectSkillRepository projectSkillRepository;
    private final TagRepository tagRepository;
    private final ProjectTagRepository projectTagRepository;
    private final UserRepository userRepository;
    private final SkillRepository skillRepository;
    private final ProjectMapper projectMapper;
    private final NotificationService notificationService;

    // =====================================================
    // CREATE PROJECT
    // =====================================================

    /**
     * Create a new project
     */
    public ProjectResponse createProject(ProjectCreateRequest request) {
        Long creatorId = SecurityUtils.getCurrentUserId();

        // Get creator
        User creator = userRepository.findById(creatorId)
                .orElseThrow(() -> new ResourceNotFoundException("Creator not found"));

        // Validate request
        validateProjectRequest(request);

        // Create project
        Project project = Project.builder()
                .creator(creator)
                .title(request.getTitle())
                .description(request.getDescription())
                .teammatesNeeded(request.getTeammatesNeeded())
                .courseName(request.getCourseName())
                .applicationDeadline(request.getApplicationDeadline())
                .projectDuration(request.getProjectDuration())
                .status(ProjectStatus.Open)
                .build();

        Project savedProject = projectRepository.save(project);

        // ✅ Add creator as team member with "Creator" role
        ProjectMember creatorMember = ProjectMember.builder()
                .project(savedProject)
                .user(creator)
                .role("Creator")
                .build();
        projectMemberRepository.save(creatorMember);

        // ✅ Add required skills
        if (request.getRequiredSkills() != null && !request.getRequiredSkills().isEmpty()) {
            addSkillsToProject(savedProject, request.getRequiredSkills(), true);
        }

        // ✅ Add optional skills
        if (request.getOptionalSkills() != null && !request.getOptionalSkills().isEmpty()) {
            addSkillsToProject(savedProject, request.getOptionalSkills(), false);
        }

        // ✅ Add tags
        if (request.getTags() != null && !request.getTags().isEmpty()) {
            addTagsToProject(savedProject, request.getTags());
        }

        log.info("Project {} created by user {}", savedProject.getProjectId(), creatorId);

        return projectMapper.toResponse(savedProject);
    }

    /**
     * Add skills to project
     */
    private void addSkillsToProject(Project project, List<String> skillNames, boolean isRequired) {
        for (String skillName : skillNames) {
            Skill skill = skillRepository.findBySkillName(skillName)
                    .orElseThrow(() -> new ResourceNotFoundException("Skill not found: " + skillName));

            ProjectSkill projectSkill = ProjectSkill.builder()
                    .project(project)
                    .skill(skill)
                    .isRequired(isRequired)
                    .build();

            projectSkillRepository.save(projectSkill);
        }
    }

    /**
     * Add tags to project
     */
    private void addTagsToProject(Project project, List<String> tagNames) {
        for (String tagName : tagNames) {
            Tag tag = tagRepository.findByTagNameIgnoreCase(tagName)
                    .orElseGet(() -> {
                        Tag newTag = Tag.builder().tagName(tagName).build();
                        return tagRepository.save(newTag);
                    });

            ProjectTag projectTag = ProjectTag.builder()
                    .project(project)
                    .tag(tag)
                    .build();
            projectTagRepository.save(projectTag);
        }
    }

    // =====================================================
    // READ PROJECT
    // =====================================================

    /**
     * Get project by ID
     */
    @Transactional(readOnly = true)
    public ProjectResponse getProjectById(Long projectId) {
        Project project = projectRepository.findByIdWithCreator(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found with id: " + projectId));

        return projectMapper.toResponse(project);
    }

    /**
     * Get all projects (paginated, sorted by recent)
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getAllProjects(Pageable pageable) {
        Page<Project> projects = projectRepository.findAllOpenProjects(pageable);
        return projects.map(projectMapper::toResponse);
    }

    /**
     * Get projects by creator
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getProjectsByCreator(Long creatorId, Pageable pageable) {
        Page<Project> projects = projectRepository.findByCreatorUserId(creatorId, pageable);
        return projects.map(projectMapper::toResponse);
    }

    /**
     * Get my projects (current user as creator)
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getMyProjects(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        return getProjectsByCreator(currentUserId, pageable);
    }

    /**
     * Get projects by status
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getProjectsByStatus(ProjectStatus status, Pageable pageable) {
        Page<Project> projects = projectRepository.findByStatus(status, pageable);
        return projects.map(projectMapper::toResponse);
    }

    // =====================================================
    // SEARCH & FILTER
    // =====================================================

    /**
     * Search projects by title/description
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> searchProjects(String query, Pageable pageable) {
        if (query == null || query.trim().isEmpty()) {
            return getAllProjects(pageable);
        }

        Page<Project> projects = projectRepository.searchProjects(query.trim(), pageable);
        return projects.map(projectMapper::toResponse);
    }

    /**
     * Find projects needing teammates
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getProjectsNeedingTeammates(Pageable pageable) {
        Page<Project> projects = projectRepository.findProjectsNeedingTeammates(pageable);
        return projects.map(projectMapper::toResponse);
    }

    /**
     * Find projects matching user's skills
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getProjectsMatchingUserSkills(Long userId, Pageable pageable) {
        Page<Project> projects = projectRepository.findProjectsMatchingUserSkills(userId, pageable);
        return projects.map(projectMapper::toResponse);
    }

    /**
     * Get projects with open applications
     */
    @Transactional(readOnly = true)
    public Page<ProjectResponse> getProjectsWithOpenApplications(Pageable pageable) {
        Page<Project> projects = projectRepository.findProjectsWithOpenApplications(pageable);
        return projects.map(projectMapper::toResponse);
    }

    // =====================================================
    // UPDATE PROJECT
    // =====================================================

    /**
     * Update project (only creator can update)
     */
    public ProjectResponse updateProject(Long projectId, ProjectUpdateRequest request) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can update
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can update project");
        }

        // ✅ Cannot update closed projects
        if (project.getStatus() == ProjectStatus.Closed) {
            throw new BadRequestException("Cannot update closed project");
        }

        // Update fields
        if (request.getTitle() != null) {
            project.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            project.setDescription(request.getDescription());
        }
        if (request.getTeammatesNeeded() != null) {
            project.setTeammatesNeeded(request.getTeammatesNeeded());
        }
        if (request.getCourseName() != null) {
            project.setCourseName(request.getCourseName());
        }
        if (request.getApplicationDeadline() != null) {
            project.setApplicationDeadline(request.getApplicationDeadline());
        }
        if (request.getProjectDuration() != null) {
            project.setProjectDuration(request.getProjectDuration());
        }

        Project updatedProject = projectRepository.save(project);

        log.info("Project {} updated by user {}", projectId, currentUserId);

        return projectMapper.toResponse(updatedProject);
    }

    // =====================================================
    // CLOSE/REOPEN PROJECT
    // =====================================================

    /**
     * Close project (no more applications accepted)
     */
    public ProjectResponse closeProject(Long projectId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can close
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can close project");
        }

        if (project.getStatus() == ProjectStatus.Closed) {
            throw new BadRequestException("Project is already closed");
        }

        project.setStatus(ProjectStatus.Closed);
        Project closedProject = projectRepository.save(project);

        log.info("Project {} closed by user {}", projectId, currentUserId);

        return projectMapper.toResponse(closedProject);
    }

    /**
     * Reopen project
     */
    public ProjectResponse reopenProject(Long projectId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can reopen
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can reopen project");
        }

        if (project.getStatus() == ProjectStatus.Open) {
            throw new BadRequestException("Project is already open");
        }

        project.setStatus(ProjectStatus.Open);
        Project reopenedProject = projectRepository.save(project);

        log.info("Project {} reopened by user {}", projectId, currentUserId);

        return projectMapper.toResponse(reopenedProject);
    }

    // =====================================================
    // DELETE PROJECT
    // =====================================================

    /**
     * Delete project (only creator, only if no accepted applications)
     */
    public void deleteProject(Long projectId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can delete
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can delete project");
        }

        // ✅ Cannot delete if has accepted members (other than creator)
        long memberCount = projectMemberRepository.countByProjectProjectId(projectId);
        if (memberCount > 1) {
            throw new BadRequestException("Cannot delete project with accepted members");
        }

        projectRepository.deleteById(projectId);

        log.info("Project {} deleted by user {}", projectId, currentUserId);
    }

    // =====================================================
    // VALIDATION
    // =====================================================

    private void validateProjectRequest(ProjectCreateRequest request) {
        if (request.getTeammatesNeeded() < 1 || request.getTeammatesNeeded() > 10) {
            throw new BadRequestException("Teammates needed must be between 1 and 10");
        }

        if (request.getApplicationDeadline() != null &&
                request.getApplicationDeadline().isBefore(LocalDate.now())) {
            throw new BadRequestException("Application deadline cannot be in the past");
        }
    }

    // =====================================================
    // HELPER METHODS
    // =====================================================

    /**
     * Get team size for project
     */
    @Transactional(readOnly = true)
    public long getProjectTeamSize(Long projectId) {
        return projectMemberRepository.countByProjectProjectId(projectId);
    }

    /**
     * Check if project is full
     */
    @Transactional(readOnly = true)
    public boolean isProjectFull(Long projectId) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        long teamSize = getProjectTeamSize(projectId);
        return teamSize >= project.getTeammatesNeeded();
    }

    /**
     * Check if user is project member
     */
    @Transactional(readOnly = true)
    public boolean isUserProjectMember(Long projectId, Long userId) {
        return projectMemberRepository.isUserProjectMember(projectId, userId);
    }

    /**
     * Check if user is project creator
     */
    @Transactional(readOnly = true)
    public boolean isUserProjectCreator(Long projectId, Long userId) {
        return projectMemberRepository.isUserProjectCreator(projectId, userId);
    }
}