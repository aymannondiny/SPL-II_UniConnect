package com.spl2.uniconnect.service.project;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectApplication;
import com.spl2.uniconnect.domain.project.ProjectMember;
import com.spl2.uniconnect.domain.project.ApplicationStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.project.ApplicationRequest;
import com.spl2.uniconnect.dto.response.project.ApplicationResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ApplicationMapper;
import com.spl2.uniconnect.repository.project.ProjectApplicationRepository;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.notification.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ProjectApplicationService {

    private final ProjectApplicationRepository applicationRepository;
    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository projectMemberRepository;
    private final UserRepository userRepository;
    private final ApplicationMapper applicationMapper;
    private final NotificationService notificationService;
    private final ProjectService projectService;

    // =====================================================
    // APPLY TO PROJECT
    // =====================================================

    /**
     * Apply to a project
     */
    public ApplicationResponse applyToProject(Long projectId, ApplicationRequest request) {
        Long applicantId = SecurityUtils.getCurrentUserId();

        // Get project
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // Get applicant
        User applicant = userRepository.findById(applicantId)
                .orElseThrow(() -> new ResourceNotFoundException("Applicant not found"));

        // ✅ Validation: Cannot apply to own project
        if (project.getCreator().getUserId().equals(applicantId)) {
            throw new BadRequestException("Cannot apply to your own project");
        }

        // ✅ Validation: Cannot apply if already member
        if (projectMemberRepository.isUserProjectMember(projectId, applicantId)) {
            throw new BadRequestException("You are already a member of this project");
        }

        // ✅ Validation: Project must be open
        if (!project.getStatus().name().equals("Open")) {
            throw new BadRequestException("Project is closed");
        }

        // ✅ Validation: Application deadline not passed
        if (project.getApplicationDeadline() != null &&
                project.getApplicationDeadline().isBefore(java.time.LocalDate.now())) {
            throw new BadRequestException("Application deadline has passed");
        }

        // ✅ Validation: Already applied
        if (applicationRepository.hasUserAppliedToProject(projectId, applicantId)) {
            throw new BadRequestException("You have already applied to this project");
        }

        // ✅ Validation: Project not full
        if (projectService.isProjectFull(projectId)) {
            throw new BadRequestException("Project is full - all positions filled");
        }

        // Create application
        ProjectApplication application = ProjectApplication.builder()
                .project(project)
                .applicant(applicant)
                .message(request.getMessage())
                .status(ApplicationStatus.Pending)
                .build();

        ProjectApplication savedApplication = applicationRepository.save(application);

        // ✅ Send notification to project creator
        notificationService.sendProjectApplicationNotification(applicant, project);

        log.info("User {} applied to project {}", applicantId, projectId);

        return applicationMapper.toResponse(savedApplication);
    }

    // =====================================================
    // MANAGE APPLICATIONS
    // =====================================================

    /**
     * Accept application (only project creator)
     */
    public ApplicationResponse acceptApplication(Long applicationId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        ProjectApplication application = applicationRepository.findByIdWithDetails(applicationId)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        // ✅ Only project creator can accept
        if (!application.getProject().getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can accept applications");
        }

        // ✅ Validation: Application must be pending
        if (application.getStatus() != ApplicationStatus.Pending) {
            throw new BadRequestException("Application is not pending");
        }

        // ✅ Validation: Project not full
        if (projectService.isProjectFull(application.getProject().getProjectId())) {
            throw new BadRequestException("Project is full - cannot accept more members");
        }

        // Update application status
        application.setStatus(ApplicationStatus.Accepted);
        application.setRespondedAt(LocalDateTime.now());

        ProjectApplication updatedApplication = applicationRepository.save(application);

        // ✅ Add applicant to project team
        ProjectMember member = ProjectMember.builder()
                .project(application.getProject())
                .user(application.getApplicant())
                .role("Member")
                .build();
        projectMemberRepository.save(member);

        // ✅ Send notification to applicant
        notificationService.sendApplicationAcceptedNotification(
                application.getApplicant(),
                application.getProject()
        );

        log.info("Application {} accepted by user {}", applicationId, currentUserId);

        return applicationMapper.toResponse(updatedApplication);
    }

    /**
     * Reject application (only project creator)
     */
    public ApplicationResponse rejectApplication(Long applicationId) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        ProjectApplication application = applicationRepository.findById(applicationId)
                .orElseThrow(() -> new ResourceNotFoundException("Application not found"));

        // ✅ Only project creator can reject
        if (!application.getProject().getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can reject applications");
        }

        // ✅ Validation: Application must be pending
        if (application.getStatus() != ApplicationStatus.Pending) {
            throw new BadRequestException("Only pending applications can be rejected");
        }

        application.setStatus(ApplicationStatus.Rejected);
        application.setRespondedAt(LocalDateTime.now());

        applicationRepository.save(application);

        // ✅ Send notification to applicant
        notificationService.sendApplicationRejectedNotification(
                application.getApplicant(),
                application.getProject()
        );

        log.info("Application {} rejected by user {}", applicationId, currentUserId);

        return applicationMapper.toResponse(application);
    }

    // =====================================================
    // GET APPLICATIONS
    // =====================================================

    /**
     * Get applications for a project (only creator can view)
     */
    @Transactional(readOnly = true)
    public Page<ApplicationResponse> getApplicationsByProject(Long projectId, Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // ✅ Only creator can view applications
        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can view applications");
        }

        Page<ProjectApplication> applications = applicationRepository.findByProjectProjectId(projectId, pageable);
        return applications.map(applicationMapper::toResponse);
    }

    /**
     * Get pending applications for a project
     */
    @Transactional(readOnly = true)
    public Page<ApplicationResponse> getPendingApplicationsByProject(Long projectId, Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        if (!project.getCreator().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("Only project creator can view applications");
        }

        Page<ProjectApplication> applications = applicationRepository.findPendingApplicationsByProject(projectId, pageable);
        return applications.map(applicationMapper::toResponse);
    }

    /**
     * Get my applications (applicant's view)
     */
    @Transactional(readOnly = true)
    public Page<ApplicationResponse> getMyApplications(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<ProjectApplication> applications = applicationRepository.findByApplicantUserId(currentUserId, pageable);
        return applications.map(applicationMapper::toResponse);
    }

    /**
     * Get pending applications by applicant
     */
    @Transactional(readOnly = true)
    public Page<ApplicationResponse> getMyPendingApplications(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<ProjectApplication> applications = applicationRepository.findPendingApplicationsByApplicant(currentUserId, pageable);
        return applications.map(applicationMapper::toResponse);
    }

    /**
     * Get accepted applications by applicant
     */
    @Transactional(readOnly = true)
    public Page<ApplicationResponse> getMyAcceptedApplications(Pageable pageable) {
        Long currentUserId = SecurityUtils.getCurrentUserId();

        Page<ProjectApplication> applications = applicationRepository.findAcceptedApplicationsByApplicant(currentUserId, pageable);
        return applications.map(applicationMapper::toResponse);
    }

    // =====================================================
    // CHECK APPLICATION STATUS
    // =====================================================

    /**
     * Get application status for a project and applicant
     */
    @Transactional(readOnly = true)
    public ApplicationStatus getApplicationStatus(Long projectId, Long userId) {
        return applicationRepository.findByProjectProjectIdAndApplicantUserId(projectId, userId)
                .map(ProjectApplication::getStatus)
                .orElse(null);
    }

    /**
     * Check if user has applied to project
     */
    @Transactional(readOnly = true)
    public boolean hasUserApplied(Long projectId, Long userId) {
        return applicationRepository.hasUserAppliedToProject(projectId, userId);
    }
}