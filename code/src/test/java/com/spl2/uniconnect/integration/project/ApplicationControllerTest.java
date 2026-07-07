package com.spl2.uniconnect.integration.project;

import com.spl2.uniconnect.integration.connection.TestSecurityUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.AfterEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectApplication;
import com.spl2.uniconnect.domain.project.ApplicationStatus;
import com.spl2.uniconnect.domain.project.ProjectStatus;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.project.ApplicationRequest;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.project.ProjectApplicationRepository;
import com.spl2.uniconnect.repository.user.UserRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ApplicationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProjectRepository projectRepository;

    @Autowired
    private ProjectApplicationRepository applicationRepository;

    private User creator;
    private User applicant;
    private Project project;
    private ProjectApplication application;

    @BeforeEach
    void setUp() {
        // Create creator
        creator = User.builder()
                .fullName("Creator Student")
                .email("creator@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        creator = userRepository.save(creator);

        // Create applicant
        applicant = User.builder()
                .fullName("Applicant Student")
                .email("applicant@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        applicant = userRepository.save(applicant);

        // Create project
        project = Project.builder()
                .creator(creator)
                .title("AI Project")
                .description("Building an AI system")
                .teammatesNeeded(3)
                .status(ProjectStatus.Open)
                .applicationDeadline(LocalDate.now().plusDays(7))
                .build();
        project = projectRepository.save(project);

        // Create application
        application = ProjectApplication.builder()
                .project(project)
                .applicant(applicant)
                .status(ApplicationStatus.Pending)
                .appliedAt(LocalDateTime.now())
                .build();
        application = applicationRepository.save(application);
    }

    @AfterEach
    void tearDown() {
        TestSecurityUtil.clearSecurityContext();
    }

    // =====================================================
    // APPLY TO PROJECT TESTS
    // =====================================================

    @Test
    void applyToProject_Success() throws Exception {
        User newApplicant = User.builder()
                .fullName("New Applicant")
                .email("newapplicant@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        newApplicant = userRepository.save(newApplicant);

        TestSecurityUtil.authenticateUser(newApplicant);

        ApplicationRequest request = ApplicationRequest.builder()
                .message("I'm very interested in this project")
                .build();

        mockMvc.perform(post("/api/projects/" + project.getProjectId() + "/applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("Pending"));
    }

    @Test
    void applyToProject_ToOwnProject_BadRequest() throws Exception {
        TestSecurityUtil.authenticateUser(creator);

        ApplicationRequest request = ApplicationRequest.builder()
                .message("Applying to own project")
                .build();

        mockMvc.perform(post("/api/projects/" + project.getProjectId() + "/applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void applyToProject_AlreadyApplied_BadRequest() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        ApplicationRequest request = ApplicationRequest.builder()
                .message("Applying again")
                .build();

        mockMvc.perform(post("/api/projects/" + project.getProjectId() + "/applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // =====================================================
    // GET APPLICATIONS TESTS
    // =====================================================

    @Test
    void getApplicationsByProject_Success() throws Exception {
        TestSecurityUtil.authenticateUser(creator);

        mockMvc.perform(get("/api/projects/" + project.getProjectId() + "/applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.totalElements").value(greaterThanOrEqualTo(1)));
    }

    @Test
    void getApplicationsByProject_NotCreator_Forbidden() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        mockMvc.perform(get("/api/projects/" + project.getProjectId() + "/applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void getPendingApplications_Success() throws Exception {
        TestSecurityUtil.authenticateUser(creator);

        mockMvc.perform(get("/api/projects/" + project.getProjectId() + "/applications/pending")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // =====================================================
    // ACCEPT APPLICATION TESTS
    // =====================================================

    @Test
    void acceptApplication_Success() throws Exception {
        TestSecurityUtil.authenticateUser(creator);

        mockMvc.perform(put("/api/projects/" + project.getProjectId() +
                        "/applications/" + application.getApplicationId() + "/accept")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("Accepted"));
    }

    @Test
    void acceptApplication_NotCreator_Forbidden() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        mockMvc.perform(put("/api/projects/" + project.getProjectId() +
                        "/applications/" + application.getApplicationId() + "/accept")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    // =====================================================
    // REJECT APPLICATION TESTS
    // =====================================================

    @Test
    void rejectApplication_Success() throws Exception {
        TestSecurityUtil.authenticateUser(creator);

        mockMvc.perform(put("/api/projects/" + project.getProjectId() +
                        "/applications/" + application.getApplicationId() + "/reject")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    // =====================================================
    // MY APPLICATIONS TESTS
    // =====================================================

    @Test
    void getMyApplications_Success() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        mockMvc.perform(get("/api/applications/my-applications")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    void getMyPendingApplications_Success() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        mockMvc.perform(get("/api/applications/my-applications/pending")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void getMyAcceptedApplications_Success() throws Exception {
        TestSecurityUtil.authenticateUser(applicant);

        mockMvc.perform(get("/api/applications/my-applications/accepted")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}