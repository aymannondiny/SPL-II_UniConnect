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
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectStatus;
import com.spl2.uniconnect.domain.skill.Skill;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.project.ProjectCreateRequest;
import com.spl2.uniconnect.dto.request.project.ProjectUpdateRequest;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.skill.SkillRepository;
import com.spl2.uniconnect.repository.user.UserRepository;

import java.time.LocalDate;
import java.util.Arrays;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ProjectControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ProjectRepository projectRepository;

    @Autowired
    private SkillRepository skillRepository;

    private User student;
    private Skill pythonSkill;
    private Skill nlpSkill;
    private Project project;

    @BeforeEach
    void setUp() {
        // Create test user
        student = User.builder()
                .fullName("Test Student")
                .email("student@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        student = userRepository.save(student);

        // Create test skills
        pythonSkill = Skill.builder()
                .skillName("Python")
                .category("Programming")
                .build();
        pythonSkill = skillRepository.save(pythonSkill);

        nlpSkill = Skill.builder()
                .skillName("NLP")
                .category("AI/ML")
                .build();
        nlpSkill = skillRepository.save(nlpSkill);

        // Create test project
        project = Project.builder()
                .creator(student)
                .title("AI Chatbot")
                .description("Building an AI-powered chatbot using NLP technologies")
                .teammatesNeeded(3)
                .status(ProjectStatus.Open)
                .build();
        project = projectRepository.save(project);
    }

    @AfterEach
    void tearDown() {
        TestSecurityUtil.clearSecurityContext();
    }

    // =====================================================
    // CREATE PROJECT TESTS
    // =====================================================

    @Test
    void createProject_Success() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        ProjectCreateRequest request = ProjectCreateRequest.builder()
                .title("New Project")
                .description("This is a detailed description of the new project we want to build")
                .teammatesNeeded(2)
                .requiredSkills(Arrays.asList("Python", "NLP"))
                .build();

        mockMvc.perform(post("/api/projects")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value(containsString("created successfully")))
                .andExpect(jsonPath("$.data.title").value("New Project"))
                .andExpect(jsonPath("$.data.status").value("Open"));
    }

    @Test
    void createProject_InvalidTeammatesCount_BadRequest() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        ProjectCreateRequest request = ProjectCreateRequest.builder()
                .title("New Project")
                .description("This is a detailed description of the new project we want to build")
                .teammatesNeeded(15)  // ❌ Max is 10
                .requiredSkills(Arrays.asList("Python"))
                .build();

        mockMvc.perform(post("/api/projects")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void createProject_PastDeadline_BadRequest() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        ProjectCreateRequest request = ProjectCreateRequest.builder()
                .title("New Project")
                .description("This is a detailed description of the new project we want to build")
                .teammatesNeeded(2)
                .applicationDeadline(LocalDate.now().minusDays(1))  // ❌ Past date
                .requiredSkills(Arrays.asList("Python"))
                .build();

        mockMvc.perform(post("/api/projects")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    // =====================================================
    // READ PROJECT TESTS
    // =====================================================

    @Test
    void getAllProjects_Success() throws Exception {
        // ✅ No authentication needed
        mockMvc.perform(get("/api/projects")
                        .contentType(MediaType.APPLICATION_JSON))
                // ❌ REMOVE .with(csrf())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.totalElements").value(greaterThanOrEqualTo(1)));
    }

    @Test
    void getProjectById_Success() throws Exception {
        // ✅ No authentication needed
        mockMvc.perform(get("/api/projects/" + project.getProjectId())
                        .contentType(MediaType.APPLICATION_JSON))
                // ❌ REMOVE .with(csrf())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(project.getProjectId()))
                .andExpect(jsonPath("$.data.title").value("AI Chatbot"));
    }

    @Test
    void getProjectById_NotFound() throws Exception {
        // ✅ No authentication needed
        mockMvc.perform(get("/api/projects/9999")
                        .contentType(MediaType.APPLICATION_JSON))
                // ❌ REMOVE .with(csrf())
                .andExpect(status().isNotFound());
    }

    // =====================================================
// SEARCH PROJECT TESTS
// =====================================================

    @Test
    void searchProjects_Success() throws Exception {
        // ✅ No authentication needed
        mockMvc.perform(get("/api/projects/search")
                        .param("query", "Chatbot")
                        .contentType(MediaType.APPLICATION_JSON))
                // ❌ REMOVE .with(csrf())
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    void getProjectsNeedingTeammates_Success() throws Exception {

        mockMvc.perform(get("/api/projects/needing-teammates")
                        .with(user("creator@test.com").roles("STUDENT"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk());
    }

    // =====================================================
    // UPDATE PROJECT TESTS
    // =====================================================

    @Test
    void updateProject_Success() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        ProjectUpdateRequest request = ProjectUpdateRequest.builder()
                .title("Updated Title")
                .build();

        mockMvc.perform(put("/api/projects/" + project.getProjectId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.title").value("Updated Title"));
    }

    @Test
    void updateProject_NotCreator_Forbidden() throws Exception {
        User otherStudent = User.builder()
                .fullName("Other Student")
                .email("other@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        otherStudent = userRepository.save(otherStudent);

        TestSecurityUtil.authenticateUser(otherStudent);

        ProjectUpdateRequest request = ProjectUpdateRequest.builder()
                .title("Updated Title")
                .build();

        mockMvc.perform(put("/api/projects/" + project.getProjectId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }

    // =====================================================
    // CLOSE/REOPEN TESTS
    // =====================================================

    @Test
    void closeProject_Success() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        mockMvc.perform(put("/api/projects/" + project.getProjectId() + "/close")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("Closed"));
    }

    @Test
    void reopenProject_Success() throws Exception {
        // First close the project
        project.setStatus(ProjectStatus.Closed);
        projectRepository.save(project);

        TestSecurityUtil.authenticateUser(student);

        mockMvc.perform(put("/api/projects/" + project.getProjectId() + "/reopen")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.status").value("Open"));
    }

    // =====================================================
    // DELETE PROJECT TESTS
    // =====================================================

    @Test
    void deleteProject_Success() throws Exception {
        TestSecurityUtil.authenticateUser(student);

        mockMvc.perform(delete("/api/projects/" + project.getProjectId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    void deleteProject_NotCreator_Forbidden() throws Exception {
        User otherStudent = User.builder()
                .fullName("Other Student")
                .email("other@university.edu")
                .passwordHash("hashedpassword")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();
        otherStudent = userRepository.save(otherStudent);

        TestSecurityUtil.authenticateUser(otherStudent);

        mockMvc.perform(delete("/api/projects/" + project.getProjectId())
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isForbidden());
    }

    // =====================================================
    // UNAUTHORIZED ACCESS TESTS
    // =====================================================

    @Test
    void createProject_Unauthorized() throws Exception {
        ProjectCreateRequest request = ProjectCreateRequest.builder()
                .title("New Project")
                .description("Description")
                .teammatesNeeded(2)
                .requiredSkills(Arrays.asList("Python"))
                .build();

        mockMvc.perform(post("/api/projects")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());
    }
}