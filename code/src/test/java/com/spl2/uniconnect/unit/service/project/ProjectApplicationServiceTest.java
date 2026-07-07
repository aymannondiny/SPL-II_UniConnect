package com.spl2.uniconnect.unit.service.project;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectApplication;
import com.spl2.uniconnect.domain.project.ApplicationStatus;
import com.spl2.uniconnect.domain.project.ProjectStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
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
import com.spl2.uniconnect.service.project.ProjectApplicationService;
import com.spl2.uniconnect.service.project.ProjectService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProjectApplicationServiceTest {

    @Mock
    private ProjectApplicationRepository applicationRepository;

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private ProjectMemberRepository projectMemberRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ApplicationMapper applicationMapper;

    @Mock
    private NotificationService notificationService;

    @Mock
    private ProjectService projectService;

    @InjectMocks
    private ProjectApplicationService applicationService;

    private User creator;
    private User applicant;
    private Project project;
    private ProjectApplication application;
    private ApplicationRequest applicationRequest;

    @BeforeEach
    void setUp() {
        creator = User.builder()
                .userId(1L)
                .fullName("John Creator")
                .email("john@university.edu")
                .role(UserRole.STUDENT)
                .build();

        applicant = User.builder()
                .userId(2L)
                .fullName("Jane Applicant")
                .email("jane@university.edu")
                .role(UserRole.STUDENT)
                .build();

        project = Project.builder()
                .projectId(1L)
                .creator(creator)
                .title("AI Chatbot")
                .description("Building an AI chatbot")
                .status(ProjectStatus.Open)
                .applicationDeadline(LocalDate.now().plusDays(7))
                .build();

        application = ProjectApplication.builder()
                .applicationId(1L)
                .project(project)
                .applicant(applicant)
                .status(ApplicationStatus.Pending)
                .appliedAt(LocalDateTime.now())
                .build();

        applicationRequest = ApplicationRequest.builder()
                .message("I'm interested in this project")
                .build();
    }

    // =====================================================
    // APPLY TO PROJECT TESTS
    // =====================================================

    @Test
    void applyToProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));
            when(applicationRepository.hasUserAppliedToProject(1L, 2L)).thenReturn(false);
            when(projectService.isProjectFull(1L)).thenReturn(false);
            when(applicationRepository.save(any(ProjectApplication.class))).thenReturn(application);
            when(applicationMapper.toResponse(application))
                    .thenReturn(ApplicationResponse.builder().id(1L).build());

            ApplicationResponse response = applicationService.applyToProject(1L, applicationRequest);

            assertNotNull(response);
            verify(notificationService).sendProjectApplicationNotification(applicant, project);
        }
    }

    @Test
    void applyToProject_ToOwnProject_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            // ✅ Mock the applicant (current user)
            when(userRepository.findById(1L)).thenReturn(Optional.of(applicant));

            // Project created by same user (1L)
            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(BadRequestException.class, () ->
                    applicationService.applyToProject(1L, applicationRequest)
            );
        }
    }

    @Test
    void applyToProject_AlreadyMember_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));
            when(projectMemberRepository.isUserProjectMember(1L, 2L)).thenReturn(true);

            assertThrows(BadRequestException.class, () -> applicationService.applyToProject(1L, applicationRequest));
        }
    }

    @Test
    void applyToProject_ProjectClosed_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            project.setStatus(ProjectStatus.Closed);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));

            assertThrows(BadRequestException.class, () -> applicationService.applyToProject(1L, applicationRequest));
        }
    }

    @Test
    void applyToProject_DeadlinePassed_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            project.setApplicationDeadline(LocalDate.now().minusDays(1));

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));

            assertThrows(BadRequestException.class, () -> applicationService.applyToProject(1L, applicationRequest));
        }
    }

    @Test
    void applyToProject_ProjectFull_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));
            when(applicationRepository.hasUserAppliedToProject(1L, 2L)).thenReturn(false);
            when(projectService.isProjectFull(1L)).thenReturn(true);

            assertThrows(BadRequestException.class, () -> applicationService.applyToProject(1L, applicationRequest));
        }
    }

    @Test
    void applyToProject_AlreadyApplied_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(userRepository.findById(2L)).thenReturn(Optional.of(applicant));
            when(applicationRepository.hasUserAppliedToProject(1L, 2L)).thenReturn(true);

            assertThrows(BadRequestException.class, () -> applicationService.applyToProject(1L, applicationRequest));
        }
    }

    // =====================================================
    // ACCEPT APPLICATION TESTS
    // =====================================================

    @Test
    void acceptApplication_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(applicationRepository.findByIdWithDetails(1L)).thenReturn(Optional.of(application));
            when(projectService.isProjectFull(1L)).thenReturn(false);
            when(applicationRepository.save(any(ProjectApplication.class))).thenReturn(application);
            when(applicationMapper.toResponse(application))
                    .thenReturn(ApplicationResponse.builder().id(1L).build());

            ApplicationResponse response = applicationService.acceptApplication(1L);

            assertNotNull(response);
            assertEquals(ApplicationStatus.Accepted, application.getStatus());
            verify(projectMemberRepository).save(any());
            verify(notificationService).sendApplicationAcceptedNotification(applicant, project);
        }
    }

    @Test
    void acceptApplication_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);

            when(applicationRepository.findByIdWithDetails(1L)).thenReturn(Optional.of(application));

            assertThrows(ForbiddenException.class, () -> applicationService.acceptApplication(1L));
        }
    }

    @Test
    void acceptApplication_NotPending_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            application.setStatus(ApplicationStatus.Accepted);

            when(applicationRepository.findByIdWithDetails(1L)).thenReturn(Optional.of(application));

            assertThrows(BadRequestException.class, () -> applicationService.acceptApplication(1L));
        }
    }

    @Test
    void acceptApplication_ProjectFull_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(applicationRepository.findByIdWithDetails(1L)).thenReturn(Optional.of(application));
            when(projectService.isProjectFull(1L)).thenReturn(true);

            assertThrows(BadRequestException.class, () -> applicationService.acceptApplication(1L));
        }
    }

    // =====================================================
    // REJECT APPLICATION TESTS
    // =====================================================

    @Test
    void rejectApplication_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(applicationRepository.findById(1L)).thenReturn(Optional.of(application));
            when(applicationRepository.save(any(ProjectApplication.class))).thenReturn(application);

            applicationService.rejectApplication(1L);

            assertEquals(ApplicationStatus.Rejected, application.getStatus());
            verify(applicationRepository).save(application);
            verify(notificationService).sendApplicationRejectedNotification(applicant, project);
        }
    }

    @Test
    void rejectApplication_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);

            when(applicationRepository.findById(1L)).thenReturn(Optional.of(application));

            assertThrows(ForbiddenException.class, () -> applicationService.rejectApplication(1L));
        }
    }

    // =====================================================
    // GET APPLICATIONS TESTS
    // =====================================================

    @Test
    void getApplicationsByProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<ProjectApplication> applicationPage = new PageImpl<>(Arrays.asList(application));

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(applicationRepository.findByProjectProjectId(1L, pageable)).thenReturn(applicationPage);
            when(applicationMapper.toResponse(application))
                    .thenReturn(ApplicationResponse.builder().id(1L).build());

            Page<ApplicationResponse> response = applicationService.getApplicationsByProject(1L, pageable);

            assertNotNull(response);
            assertEquals(1, response.getTotalElements());
        }
    }

    @Test
    void getApplicationsByProject_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);

            Pageable pageable = PageRequest.of(0, 20);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(ForbiddenException.class, () -> applicationService.getApplicationsByProject(1L, pageable));
        }
    }

    @Test
    void getMyApplications_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(2L);

            Pageable pageable = PageRequest.of(0, 20);
            Page<ProjectApplication> applicationPage = new PageImpl<>(Arrays.asList(application));

            when(applicationRepository.findByApplicantUserId(2L, pageable)).thenReturn(applicationPage);
            when(applicationMapper.toResponse(application))
                    .thenReturn(ApplicationResponse.builder().id(1L).build());

            Page<ApplicationResponse> response = applicationService.getMyApplications(pageable);

            assertNotNull(response);
            assertEquals(1, response.getTotalElements());
        }
    }

    // =====================================================
    // APPLICATION STATUS TESTS
    // =====================================================

    @Test
    void getApplicationStatus_Success() {
        when(applicationRepository.findByProjectProjectIdAndApplicantUserId(1L, 2L))
                .thenReturn(Optional.of(application));

        ApplicationStatus status = applicationService.getApplicationStatus(1L, 2L);

        assertEquals(ApplicationStatus.Pending, status);
    }

    @Test
    void hasUserApplied_True() {
        when(applicationRepository.hasUserAppliedToProject(1L, 2L)).thenReturn(true);

        boolean hasApplied = applicationService.hasUserApplied(1L, 2L);

        assertTrue(hasApplied);
    }

    @Test
    void hasUserApplied_False() {
        when(applicationRepository.hasUserAppliedToProject(1L, 2L)).thenReturn(false);

        boolean hasApplied = applicationService.hasUserApplied(1L, 2L);

        assertFalse(hasApplied);
    }
}