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
import com.spl2.uniconnect.domain.project.ProjectStatus;
import com.spl2.uniconnect.domain.skill.Skill;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.project.ProjectCreateRequest;
import com.spl2.uniconnect.dto.request.project.ProjectUpdateRequest;
import com.spl2.uniconnect.dto.response.project.ProjectResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.mapper.ProjectMapper;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.project.ProjectApplicationRepository;
import com.spl2.uniconnect.repository.project.ProjectSkillRepository;
import com.spl2.uniconnect.repository.project.ProjectTagRepository;
import com.spl2.uniconnect.repository.skill.SkillRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.notification.NotificationService;
import com.spl2.uniconnect.service.project.ProjectService;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ProjectServiceTest {

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private ProjectMemberRepository projectMemberRepository;

    @Mock
    private ProjectApplicationRepository projectApplicationRepository;

    @Mock
    private ProjectSkillRepository projectSkillRepository;

    @Mock
    private SkillRepository skillRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ProjectTagRepository projectTagRepository;

    @Mock
    private ProjectMapper projectMapper;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private ProjectService projectService;

    private User creator;
    private Project project;
    private ProjectCreateRequest createRequest;
    private ProjectResponse projectResponse;

    @BeforeEach
    void setUp() {
        creator = User.builder()
                .userId(1L)
                .fullName("John Student")
                .email("john@university.edu")
                .role(UserRole.STUDENT)
                .build();

        project = Project.builder()
                .projectId(1L)
                .creator(creator)
                .title("AI Chatbot")
                .description("Building an AI-powered chatbot using NLP")
                .teammatesNeeded(3)
                .status(ProjectStatus.Open)
                .createdAt(LocalDateTime.now())
                .build();

        createRequest = ProjectCreateRequest.builder()
                .title("AI Chatbot")
                .description("Building an AI-powered chatbot using NLP")
                .teammatesNeeded(3)
                .requiredSkills(Arrays.asList("Python", "NLP"))
                .optionalSkills(Arrays.asList("Machine Learning"))
                .build();

        projectResponse = ProjectResponse.builder()
                .id(1L)
                .title("AI Chatbot")
                .status("Open")
                .build();
    }

    // =====================================================
    // CREATE PROJECT TESTS
    // =====================================================

    @Test
    void createProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(userRepository.findById(1L)).thenReturn(Optional.of(creator));
            when(projectRepository.save(any(Project.class))).thenReturn(project);

            // ✅ Mock all required skills
            when(skillRepository.findBySkillName("Python"))
                    .thenReturn(Optional.of(Skill.builder().skillId(1L).skillName("Python").build()));
            when(skillRepository.findBySkillName("NLP"))
                    .thenReturn(Optional.of(Skill.builder().skillId(2L).skillName("NLP").build()));

            // ✅ ADD THIS: Mock optional skills too
            when(skillRepository.findBySkillName("Machine Learning"))
                    .thenReturn(Optional.of(Skill.builder().skillId(3L).skillName("Machine Learning").build()));

            when(projectMapper.toResponse(project)).thenReturn(projectResponse);

            ProjectResponse response = projectService.createProject(createRequest);

            assertNotNull(response);
            assertEquals("AI Chatbot", response.getTitle());
            verify(projectRepository).save(any(Project.class));
            verify(projectMemberRepository).save(any());  // Creator added as member
        }
    }

    @Test
    void createProject_InvalidTeammatesCount_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            createRequest.setTeammatesNeeded(11);  // Max is 10

            when(userRepository.findById(1L)).thenReturn(Optional.of(creator));

            assertThrows(BadRequestException.class, () -> projectService.createProject(createRequest));
        }
    }

    @Test
    void createProject_PastDeadline_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            createRequest.setApplicationDeadline(LocalDate.now().minusDays(1));  // Past date

            when(userRepository.findById(1L)).thenReturn(Optional.of(creator));

            assertThrows(BadRequestException.class, () -> projectService.createProject(createRequest));
        }
    }

    @Test
    void createProject_SkillNotFound_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(userRepository.findById(1L)).thenReturn(Optional.of(creator));
            when(skillRepository.findBySkillName("Python")).thenReturn(Optional.empty());

            assertThrows(ResourceNotFoundException.class, () -> projectService.createProject(createRequest));
        }
    }

    // =====================================================
    // READ PROJECT TESTS
    // =====================================================

    @Test
    void getProjectById_Success() {
        when(projectRepository.findByIdWithCreator(1L)).thenReturn(Optional.of(project));
        when(projectMapper.toResponse(project)).thenReturn(projectResponse);

        ProjectResponse response = projectService.getProjectById(1L);

        assertNotNull(response);
        assertEquals(1L, response.getId());
        verify(projectRepository).findByIdWithCreator(1L);
    }

    @Test
    void getProjectById_NotFound_ThrowsException() {
        when(projectRepository.findByIdWithCreator(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> projectService.getProjectById(999L));
    }

    @Test
    void getAllProjects_Success() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<Project> projectPage = new PageImpl<>(Arrays.asList(project));

        when(projectRepository.findAllOpenProjects(pageable)).thenReturn(projectPage);
        when(projectMapper.toResponse(project)).thenReturn(projectResponse);

        Page<ProjectResponse> response = projectService.getAllProjects(pageable);

        assertNotNull(response);
        assertEquals(1, response.getTotalElements());
    }

    // =====================================================
    // SEARCH PROJECT TESTS
    // =====================================================

    @Test
    void searchProjects_Success() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<Project> projectPage = new PageImpl<>(Arrays.asList(project));

        when(projectRepository.searchProjects("AI", pageable)).thenReturn(projectPage);
        when(projectMapper.toResponse(project)).thenReturn(projectResponse);

        Page<ProjectResponse> response = projectService.searchProjects("AI", pageable);

        assertNotNull(response);
        assertEquals(1, response.getTotalElements());
    }

    @Test
    void searchProjects_EmptyQuery_ReturnAllProjects() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<Project> projectPage = new PageImpl<>(Arrays.asList(project));

        when(projectRepository.findAllOpenProjects(pageable)).thenReturn(projectPage);
        when(projectMapper.toResponse(project)).thenReturn(projectResponse);

        Page<ProjectResponse> response = projectService.searchProjects(null, pageable);

        assertNotNull(response);
        verify(projectRepository).findAllOpenProjects(pageable);
    }

    // =====================================================
    // UPDATE PROJECT TESTS
    // =====================================================

    @Test
    void updateProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            ProjectUpdateRequest updateRequest = ProjectUpdateRequest.builder()
                    .title("Updated Title")
                    .build();

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(projectRepository.save(any(Project.class))).thenReturn(project);
            when(projectMapper.toResponse(project)).thenReturn(projectResponse);

            ProjectResponse response = projectService.updateProject(1L, updateRequest);

            assertNotNull(response);
            verify(projectRepository).save(any(Project.class));
        }
    }

    @Test
    void updateProject_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);  // Different user

            ProjectUpdateRequest updateRequest = ProjectUpdateRequest.builder()
                    .title("Updated Title")
                    .build();

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(ForbiddenException.class, () -> projectService.updateProject(1L, updateRequest));
        }
    }

    @Test
    void updateProject_ClosedProject_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            project.setStatus(ProjectStatus.Closed);

            ProjectUpdateRequest updateRequest = ProjectUpdateRequest.builder()
                    .title("Updated Title")
                    .build();

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(BadRequestException.class, () -> projectService.updateProject(1L, updateRequest));
        }
    }

    // =====================================================
    // CLOSE/REOPEN TESTS
    // =====================================================

    @Test
    void closeProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(projectRepository.save(any(Project.class))).thenReturn(project);
            when(projectMapper.toResponse(project)).thenReturn(projectResponse);

            ProjectResponse response = projectService.closeProject(1L);

            assertNotNull(response);
            assertEquals(ProjectStatus.Closed, project.getStatus());
        }
    }

    @Test
    void closeProject_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(ForbiddenException.class, () -> projectService.closeProject(1L));
        }
    }

    @Test
    void reopenProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            project.setStatus(ProjectStatus.Closed);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(projectRepository.save(any(Project.class))).thenReturn(project);
            when(projectMapper.toResponse(project)).thenReturn(projectResponse);

            ProjectResponse response = projectService.reopenProject(1L);

            assertNotNull(response);
            assertEquals(ProjectStatus.Open, project.getStatus());
        }
    }

    // =====================================================
    // DELETE PROJECT TESTS
    // =====================================================

    @Test
    void deleteProject_Success() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(projectMemberRepository.countByProjectProjectId(1L)).thenReturn(1L);  // Only creator

            projectService.deleteProject(1L);

            verify(projectRepository).deleteById(1L);
        }
    }

    @Test
    void deleteProject_NotCreator_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(999L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));

            assertThrows(ForbiddenException.class, () -> projectService.deleteProject(1L));
        }
    }

    @Test
    void deleteProject_HasMembers_ThrowsException() {
        try (MockedStatic<SecurityUtils> mockedSecurityUtils = mockStatic(SecurityUtils.class)) {
            mockedSecurityUtils.when(SecurityUtils::getCurrentUserId).thenReturn(1L);

            when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
            when(projectMemberRepository.countByProjectProjectId(1L)).thenReturn(3L);  // Has members

            assertThrows(BadRequestException.class, () -> projectService.deleteProject(1L));
        }
    }

    // =====================================================
    // HELPER METHOD TESTS
    // =====================================================

    @Test
    void isProjectFull_True() {
        when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
        when(projectMemberRepository.countByProjectProjectId(1L)).thenReturn(3L);  // Same as needed

        boolean isFull = projectService.isProjectFull(1L);

        assertTrue(isFull);
    }

    @Test
    void isProjectFull_False() {
        when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
        when(projectMemberRepository.countByProjectProjectId(1L)).thenReturn(1L);  // Less than needed

        boolean isFull = projectService.isProjectFull(1L);

        assertFalse(isFull);
    }

    @Test
    void isUserProjectMember_True() {
        when(projectMemberRepository.isUserProjectMember(1L, 2L)).thenReturn(true);

        boolean isMember = projectService.isUserProjectMember(1L, 2L);

        assertTrue(isMember);
    }

    @Test
    void isUserProjectCreator_True() {
        when(projectMemberRepository.isUserProjectCreator(1L, 1L)).thenReturn(true);

        boolean isCreator = projectService.isUserProjectCreator(1L, 1L);

        assertTrue(isCreator);
    }
}