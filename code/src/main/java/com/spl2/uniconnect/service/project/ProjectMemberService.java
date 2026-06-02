package com.spl2.uniconnect.service.project;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectMember;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.response.project.TeamMemberResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ProjectMemberMapper;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProjectMemberService {

    private final ProjectMemberRepository projectMemberRepository;
    private final ProjectRepository projectRepository;
    private final UserRepository userRepository;
    private final ProjectMemberMapper projectMemberMapper;

    // =====================================================
    // ADD MEMBER (via Application Acceptance)
    // =====================================================

    /**
     * Add member to project (called when application is accepted)
     * This is called by ProjectApplicationService
     */
    public ProjectMember addMember(Long projectId, Long userId, String role) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        // ✅ Check if already member
        if (projectMemberRepository.isUserProjectMember(projectId, userId)) {
            throw new BadRequestException("User is already a member of this project");
        }

        ProjectMember member = ProjectMember.builder()
                .project(project)
                .user(user)
                .role(role)
                .build();

        ProjectMember savedMember = projectMemberRepository.save(member);

        log.info("User {} added to project {} as {}", userId, projectId, role);

        return savedMember;
    }

    // =====================================================
    // REMOVE MEMBER
    // =====================================================

    /**
     * Remove member from project (only creator can do this)
     */
    public void removeMember(Long projectId, Long userId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can remove members
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can remove members");
        }

        ProjectMember member = projectMemberRepository.findByProjectProjectIdAndUserUserId(projectId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Member not found"));

        // ✅ Cannot remove creator
        if ("Creator".equals(member.getRole())) {
            throw new BadRequestException("Cannot remove project creator");
        }

        projectMemberRepository.delete(member);

        log.info("User {} removed from project {}", userId, projectId);
    }

    // =====================================================
    // GET TEAM MEMBERS
    // =====================================================

    /**
     * Get all team members for a project
     */
    @Transactional(readOnly = true)
    public Page<TeamMemberResponse> getTeamMembers(Long projectId, Pageable pageable) {
        Page<ProjectMember> members = projectMemberRepository.findByProjectProjectId(projectId, pageable);
        return members.map(projectMemberMapper::toResponse);
    }

    /**
     * Get all team members (list, not paginated)
     */
    @Transactional(readOnly = true)
    public List<TeamMemberResponse> getAllTeamMembers(Long projectId) {
        List<ProjectMember> members = projectMemberRepository.findAllMembersByProject(projectId);
        return members.stream()
                .map(projectMemberMapper::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Get project creator
     */
    @Transactional(readOnly = true)
    public TeamMemberResponse getProjectCreator(Long projectId) {
        ProjectMember creator = projectMemberRepository.findProjectCreator(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project creator not found"));

        return projectMemberMapper.toResponse(creator);
    }

    /**
     * Get team members excluding creator
     */
    @Transactional(readOnly = true)
    public List<TeamMemberResponse> getTeamMembersExcludingCreator(Long projectId) {
        List<ProjectMember> members = projectMemberRepository.findTeamMembersExcludingCreator(projectId);
        return members.stream()
                .map(projectMemberMapper::toResponse)
                .collect(Collectors.toList());
    }

    // =====================================================
    // GET USER'S PROJECTS
    // =====================================================

    /**
     * Get all projects user is member of
     */
    @Transactional(readOnly = true)
    public Page<ProjectMember> getUserProjects(Long userId, Pageable pageable) {
        return projectMemberRepository.findByUserUserId(userId, pageable);
    }

    /**
     * Get all projects current user is member of
     */
    @Transactional(readOnly = true)
    public Page<ProjectMember> getMyProjects(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();
        return getUserProjects(currentUserId, pageable);
    }

    /**
     * Get projects user created
     */
    @Transactional(readOnly = true)
    public List<ProjectMember> getProjectsCreatedByUser(Long userId) {
        return projectMemberRepository.findProjectsCreatedByUser(userId);
    }

    // =====================================================
    // COUNTING & CHECKING
    // =====================================================

    /**
     * Get team size for a project
     */
    @Transactional(readOnly = true)
    public long getTeamSize(Long projectId) {
        return projectMemberRepository.countByProjectProjectId(projectId);
    }

    /**
     * Count projects user is member of
     */
    @Transactional(readOnly = true)
    public long countUserProjects(Long userId) {
        return projectMemberRepository.countByUserUserId(userId);
    }

    /**
     * Check if user is member
     */
    @Transactional(readOnly = true)
    public boolean isUserMember(Long projectId, Long userId) {
        return projectMemberRepository.isUserProjectMember(projectId, userId);
    }

    /**
     * Check if user is creator
     */
    @Transactional(readOnly = true)
    public boolean isUserCreator(Long projectId, Long userId) {
        return projectMemberRepository.isUserProjectCreator(projectId, userId);
    }

    /**
     * Get all member user IDs
     */
    @Transactional(readOnly = true)
    public List<Long> getTeamMemberUserIds(Long projectId) {
        return projectMemberRepository.findAllMemberUserIds(projectId);
    }
}