package com.spl2.uniconnect.unit.service.project;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.project.ProjectStatus;
import com.spl2.uniconnect.domain.skill.Skill;
import com.spl2.uniconnect.domain.skill.UserSkill;
import com.spl2.uniconnect.domain.skill.ProficiencyLevel;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.response.project.TeammateRecommendation;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.project.ProjectSkillRepository;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.skill.UserSkillRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.connection.ConnectionService;
import com.spl2.uniconnect.service.project.TeammateMatchingService;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class TeammateMatchingServiceTest {

    @Mock
    private ProjectRepository projectRepository;

    @Mock
    private ProjectSkillRepository projectSkillRepository;

    @Mock
    private ProjectMemberRepository projectMemberRepository;

    @Mock
    private UserSkillRepository userSkillRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private ConnectionService connectionService;

    @InjectMocks
    private TeammateMatchingService matchingService;

    private User creator;
    private User candidate1;
    private User candidate2;
    private Project project;
    private Skill pythonSkill;
    private Skill nlpSkill;

    @BeforeEach
    void setUp() {
        creator = User.builder()
                .userId(1L)
                .fullName("Project Creator")
                .email("creator@university.edu")
                .role(UserRole.STUDENT)
                .build();

        candidate1 = User.builder()
                .userId(2L)
                .fullName("Candidate 1")
                .email("candidate1@university.edu")
                .role(UserRole.STUDENT)
                .build();

        candidate2 = User.builder()
                .userId(3L)
                .fullName("Candidate 2")
                .email("candidate2@university.edu")
                .role(UserRole.STUDENT)
                .build();

        project = Project.builder()
                .projectId(1L)
                .creator(creator)
                .title("AI Chatbot")
                .description("Building an AI chatbot")
                .status(ProjectStatus.Open)
                .build();

        pythonSkill = Skill.builder()
                .skillId(1L)
                .skillName("Python")
                .category("Programming")
                .build();

        nlpSkill = Skill.builder()
                .skillId(2L)
                .skillName("NLP")
                .category("AI/ML")
                .build();
    }

    // =====================================================
    // SKILL MATCHING TESTS
    // =====================================================

    @Test
    void getTeammateRecommendations_Success() {
        when(projectRepository.findById(1L)).thenReturn(Optional.of(project));
        when(projectMemberRepository.findAllMemberUserIds(1L)).thenReturn(Arrays.asList(1L));
        when(userRepository.findAll()).thenReturn(Arrays.asList(creator, candidate1, candidate2));

        when(projectSkillRepository.getRequiredSkillNames(1L))
                .thenReturn(Arrays.asList("Python", "NLP"));
        when(projectSkillRepository.getOptionalSkillNames(1L))
                .thenReturn(Arrays.asList());

        // Candidate 1: Has Python & NLP
        when(userSkillRepository.findByUserUserId(2L)).thenReturn(Arrays.asList(
                UserSkill.builder().skill(pythonSkill).user(candidate1).proficiencyLevel(ProficiencyLevel.Advanced).build(),
                UserSkill.builder().skill(nlpSkill).user(candidate1).proficiencyLevel(ProficiencyLevel.Intermediate).build()
        ));

        // Candidate 2: Has only Python
        when(userSkillRepository.findByUserUserId(3L)).thenReturn(Arrays.asList(
                UserSkill.builder().skill(pythonSkill).user(candidate2).proficiencyLevel(ProficiencyLevel.Intermediate).build()
        ));

        when(connectionService.areUsersConnected(2L, 1L)).thenReturn(false);
        when(connectionService.getConnectionIds(2L)).thenReturn(Arrays.asList());
        when(connectionService.getConnectionIds(1L)).thenReturn(Arrays.asList());

        when(connectionService.areUsersConnected(3L, 1L)).thenReturn(false);
        when(connectionService.getConnectionIds(3L)).thenReturn(Arrays.asList());

        List<TeammateRecommendation> recommendations = matchingService.getTeammateRecommendations(1L, 10);

        assertNotNull(recommendations);
        assertFalse(recommendations.isEmpty());
        // Candidate 1 should rank higher (has both skills)
        assertEquals(candidate1.getUserId(), recommendations.get(0).getCandidateId());
    }

    @Test
    void getTeammateRecommendations_ProjectNotFound_ThrowsException() {
        when(projectRepository.findById(999L)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> matchingService.getTeammateRecommendations(999L, 10));
    }

    // =====================================================
    // SKILL SEARCH TESTS
    // =====================================================

    @Test
    void searchTeammatesBySkills_Success() {
        when(userRepository.findAll()).thenReturn(Arrays.asList(candidate1, candidate2));

        // Candidate 1: Has both skills
        when(userSkillRepository.findByUserUserId(2L)).thenReturn(Arrays.asList(
                UserSkill.builder().skill(pythonSkill).user(candidate1).build(),
                UserSkill.builder().skill(nlpSkill).user(candidate1).build()
        ));

        // Candidate 2: Has only one skill
        when(userSkillRepository.findByUserUserId(3L)).thenReturn(Arrays.asList(
                UserSkill.builder().skill(pythonSkill).user(candidate2).build()
        ));

        List<TeammateRecommendation> results = matchingService.searchTeammatesBySkills(
                Arrays.asList("Python", "NLP"),
                Arrays.asList(),
                10
        );

        assertNotNull(results);
        assertFalse(results.isEmpty());
        // Candidate 1 should rank higher
        assertEquals(candidate1.getUserId(), results.get(0).getCandidateId());
    }

    @Test
    void searchTeammatesBySkills_Empty() {
        when(userRepository.findAll()).thenReturn(Arrays.asList(candidate1, candidate2));

        // No one has the required skills
        when(userSkillRepository.findByUserUserId(2L)).thenReturn(Arrays.asList());
        when(userSkillRepository.findByUserUserId(3L)).thenReturn(Arrays.asList());

        List<TeammateRecommendation> results = matchingService.searchTeammatesBySkills(
                Arrays.asList("Java", "Kubernetes"),
                Arrays.asList(),
                10
        );

        assertNotNull(results);
        assertTrue(results.isEmpty());
    }

}