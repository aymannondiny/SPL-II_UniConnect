package com.spl2.uniconnect.service.project;

import com.spl2.uniconnect.domain.project.Project;
import com.spl2.uniconnect.domain.skill.UserSkill;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.response.project.TeammateRecommendation;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.project.ProjectMemberRepository;
import com.spl2.uniconnect.repository.project.ProjectRepository;
import com.spl2.uniconnect.repository.project.ProjectSkillRepository;
import com.spl2.uniconnect.repository.skill.UserSkillRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.connection.ConnectionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class TeammateMatchingService {

    private final ProjectRepository projectRepository;
    private final ProjectSkillRepository projectSkillRepository;
    private final UserSkillRepository userSkillRepository;
    private final UserRepository userRepository;
    private final ConnectionService connectionService;
    private final ProjectMemberRepository projectMemberRepository;

    // =====================================================
    // MATCHING ALGORITHM CONSTANTS
    // =====================================================

    private static final double SKILL_MATCH_WEIGHT = 0.40;
    private static final double GRAPH_PROXIMITY_WEIGHT = 0.30;
    private static final double AVAILABILITY_WEIGHT = 0.15;
    private static final double COMMON_INTERESTS_WEIGHT = 0.15;

    private static final double REQUIRED_SKILL_WEIGHT = 0.70;
    private static final double OPTIONAL_SKILL_WEIGHT = 0.30;

    // =====================================================
    // MAIN MATCHING FUNCTION
    // =====================================================

    /**
     * Get top N teammate recommendations for a project
     * Uses multi-factor scoring algorithm
     */
    public List<TeammateRecommendation> getTeammateRecommendations(Long projectId, int topN) {
        Project project = projectRepository.findById(projectId)
                .orElseThrow(() -> new ResourceNotFoundException("Project not found"));

        // Get all users except:
        // 1. Project creator
        // 2. Existing project members
        List<Long> excludedUserIds = projectMemberRepository.findAllMemberUserIds(projectId);

        // Get all users in system
        List<User> allUsers = userRepository.findAll();

        // Filter out excluded users and closed projects
        List<User> candidates = allUsers.stream()
                .filter(u -> !excludedUserIds.contains(u.getUserId()))
                .collect(Collectors.toList());

        // Score all candidates
        List<TeammateRecommendation> recommendations = candidates.stream()
                .map(candidate -> scoreCandidate(candidate, project))
                .filter(rec -> rec.getTotalScore() > 0)  // Only positive scores
                .sorted(Comparator.comparingDouble(TeammateRecommendation::getTotalScore).reversed())
                .limit(topN)
                .collect(Collectors.toList());

        log.info("Generated {} recommendations for project {}", recommendations.size(), projectId);

        return recommendations;
    }

    /**
     * Score a single candidate against a project
     */
    private TeammateRecommendation scoreCandidate(User candidate, Project project) {
        // Get required and optional skills
        List<String> requiredSkills = projectSkillRepository.getRequiredSkillNames(project.getProjectId());
        List<String> optionalSkills = projectSkillRepository.getOptionalSkillNames(project.getProjectId());

        // Get candidate's skills
        Set<String> candidateSkillNames = userSkillRepository.findByUserUserId(candidate.getUserId())
                .stream()
                .map(us -> us.getSkill().getSkillName())
                .collect(Collectors.toSet());

        // Calculate individual scores
        double skillMatchScore = calculateSkillMatchScore(candidateSkillNames, requiredSkills, optionalSkills);
        double graphProximityScore = calculateGraphProximityScore(candidate.getUserId(), project.getCreator().getUserId());
        double availabilityScore = calculateAvailabilityScore(candidate);
        double commonInterestsScore = calculateCommonInterestsScore(candidate, project);

        // Calculate weighted total score (0-100)
        double totalScore =
                (skillMatchScore * SKILL_MATCH_WEIGHT) +
                        (graphProximityScore * GRAPH_PROXIMITY_WEIGHT) +
                        (availabilityScore * AVAILABILITY_WEIGHT) +
                        (commonInterestsScore * COMMON_INTERESTS_WEIGHT);

        return TeammateRecommendation.builder()
                .candidateId(candidate.getUserId())
                .candidateName(candidate.getFullName())
                .candidateEmail(candidate.getEmail())
                .skillMatchScore(skillMatchScore)
                .graphProximityScore(graphProximityScore)
                .availabilityScore(availabilityScore)
                .commonInterestsScore(commonInterestsScore)
                .totalScore(totalScore)
                .matchingSkills(getMatchingSkills(candidateSkillNames, requiredSkills))
                .missingSkills(getMissingSkills(candidateSkillNames, requiredSkills))
                .build();
    }

    // =====================================================
    // SKILL MATCHING (Jaccard Similarity)
    // =====================================================

    /**
     * Calculate skill match score (0-100)
     * Formula: 0.7 * R_match + 0.3 * O_match
     *
     * R_match = |userSkills ∩ requiredSkills| / |requiredSkills|
     * O_match = |userSkills ∩ optionalSkills| / |optionalSkills|
     */
    private double calculateSkillMatchScore(Set<String> userSkills, List<String> requiredSkills, List<String> optionalSkills) {
        // Calculate required skills match (Jaccard similarity)
        double requiredMatch = calculateJaccardSimilarity(userSkills, new HashSet<>(requiredSkills));

        // Calculate optional skills match
        double optionalMatch = optionalSkills.isEmpty() ? 0 :
                calculateJaccardSimilarity(userSkills, new HashSet<>(optionalSkills));

        // Weighted combination
        double skillScore = (requiredMatch * REQUIRED_SKILL_WEIGHT) + (optionalMatch * OPTIONAL_SKILL_WEIGHT);

        return skillScore * 100;  // Convert to 0-100 scale
    }

    /**
     * Jaccard Similarity: |A ∩ B| / |A ∪ B|
     */
    private double calculateJaccardSimilarity(Set<String> set1, Set<String> set2) {
        if (set1.isEmpty() && set2.isEmpty()) {
            return 1.0;  // Both empty = perfect match
        }

        Set<String> intersection = new HashSet<>(set1);
        intersection.retainAll(set2);

        Set<String> union = new HashSet<>(set1);
        union.addAll(set2);

        if (union.isEmpty()) {
            return 0;
        }

        return (double) intersection.size() / union.size();
    }

    // =====================================================
    // GRAPH PROXIMITY SCORING
    // =====================================================

    /**
     * Calculate graph proximity score (0-100)
     * Based on connection distance:
     * - Same user = 1.0 (100)
     * - 1 hop (direct connection) = 0.9 (90)
     * - 2 hops (mutual connection) = 0.7 (70)
     * - 3+ hops = 0.4 (40)
     * - No connection = 0 (0)
     */
    private double calculateGraphProximityScore(Long userId, Long creatorId) {
        if (userId.equals(creatorId)) {
            return 100.0;  // Same user
        }

        // Check if direct connection (1 hop)
        if (connectionService.areUsersConnected(userId, creatorId)) {
            return 90.0;  // 1 hop
        }

        // Check for mutual connections (2 hops)
        List<Long> userConnections = connectionService.getConnectionIds(userId);
        List<Long> creatorConnections = connectionService.getConnectionIds(creatorId);

        if (!userConnections.isEmpty() && !creatorConnections.isEmpty()) {
            // Find intersection (mutual connections)
            userConnections.retainAll(creatorConnections);
            if (!userConnections.isEmpty()) {
                return 70.0;  // 2 hops
            }
        }

        // 3+ hops or no connection
        return 40.0;
    }

    // =====================================================
    // AVAILABILITY SCORING
    // =====================================================

    /**
     * Calculate availability score (0-100)
     * Check if user has profile flag "looking for teammates"
     * If StudentProfile exists and lookingForTeammates = true, score = 100
     * Otherwise = 50 (neutral)
     */
    private double calculateAvailabilityScore(User candidate) {
        // TODO: Check StudentProfile.lookingForTeammates flag
        // For now, return neutral score
        return 50.0;
    }

    // =====================================================
    // COMMON INTERESTS SCORING
    // =====================================================

    /**
     * Calculate common interests score (0-100)
     * Based on shared interests with project creator
     */
    private double calculateCommonInterestsScore(User candidate, Project project) {
        // Get candidate's interests
        List<String> candidateInterests = getUserInterestNames(candidate.getUserId());

        // Get creator's interests
        List<String> creatorInterests = getUserInterestNames(project.getCreator().getUserId());

        if (candidateInterests.isEmpty() || creatorInterests.isEmpty()) {
            return 0.0;  // Cannot calculate without interests
        }

        // Calculate Jaccard similarity on interests
        double interestSimilarity = calculateJaccardSimilarity(
                new HashSet<>(candidateInterests),
                new HashSet<>(creatorInterests)
        );

        return interestSimilarity * 100;
    }

    /**
     * Get user's interests
     */
    private List<String> getUserInterestNames(Long userId) {
        // TODO: Query UserInterest repository
        // For now, return empty list
        return new ArrayList<>();
    }

    // =====================================================
    // HELPER METHODS
    // =====================================================

    /**
     * Get matching skill names (intersection)
     */
    private List<String> getMatchingSkills(Set<String> userSkills, List<String> requiredSkills) {
        return requiredSkills.stream()
                .filter(userSkills::contains)
                .collect(Collectors.toList());
    }

    /**
     * Get missing skill names (in required but not in user's skills)
     */
    private List<String> getMissingSkills(Set<String> userSkills, List<String> requiredSkills) {
        return requiredSkills.stream()
                .filter(skill -> !userSkills.contains(skill))
                .collect(Collectors.toList());
    }

    // =====================================================
    // SEARCH TEAMMATES BY SKILLS (without project)
    // =====================================================

    /**
     * Search for teammates by required and optional skills
     */
    public List<TeammateRecommendation> searchTeammatesBySkills(
            List<String> requiredSkills,
            List<String> optionalSkills,
            int topN) {

        // Get all users
        List<User> allUsers = userRepository.findAll();

        // Score all users
        List<TeammateRecommendation> results = allUsers.stream()
                .map(user -> scoreUserBySkills(user, requiredSkills, optionalSkills))
                .filter(rec -> rec.getTotalScore() > 0)
                .sorted(Comparator.comparingDouble(TeammateRecommendation::getTotalScore).reversed())
                .limit(topN)
                .collect(Collectors.toList());

        log.info("Found {} teammates matching skills", results.size());

        return results;
    }

    /**
     * Score user by skills only (no project context)
     */
    private TeammateRecommendation scoreUserBySkills(User user, List<String> requiredSkills, List<String> optionalSkills) {
        Set<String> userSkills = userSkillRepository.findByUserUserId(user.getUserId())
                .stream()
                .map(us -> us.getSkill().getSkillName())
                .collect(Collectors.toSet());

        double skillScore = calculateSkillMatchScore(userSkills, requiredSkills, optionalSkills);

        return TeammateRecommendation.builder()
                .candidateId(user.getUserId())
                .candidateName(user.getFullName())
                .candidateEmail(user.getEmail())
                .skillMatchScore(skillScore)
                .totalScore(skillScore)
                .matchingSkills(getMatchingSkills(userSkills, requiredSkills))
                .missingSkills(getMissingSkills(userSkills, requiredSkills))
                .build();
    }
}