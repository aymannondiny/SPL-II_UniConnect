package com.spl2.uniconnect.dto.response.project;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TeammateRecommendation {

    private Long candidateId;

    private String candidateName;

    private String candidateEmail;

    // ✅ Individual Scores (0-100)
    private Double skillMatchScore;

    private Double graphProximityScore;

    private Double availabilityScore;

    private Double commonInterestsScore;

    // ✅ Total Score (weighted average, 0-100)
    private Double totalScore;

    // ✅ Skill Details
    private List<String> matchingSkills;

    private List<String> missingSkills;
}