package com.uniconnect.project.service;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ProjectRecommendationScorerTests {
    private final ProjectRecommendationScorer scorer = new ProjectRecommendationScorer();

    @Test
    void approvedFormulaProducesSeventyTwoPointFiveExample() {
        var score = scorer.score(
                List.of("java", "sql"), List.of("docker", "git"),
                List.of("SQL", " java "), List.of("distributed systems", "ai"),
                List.of("AI"), true).orElseThrow();

        assertThat(score.skillPoints()).isEqualByComparingTo("52.50");
        assertThat(score.interestPoints()).isEqualByComparingTo("10.00");
        assertThat(score.connectionPoints()).isEqualByComparingTo("10.00");
        assertThat(score.score()).isEqualByComparingTo("72.50");
    }

    @Test
    void requiredAndOptionalWeightsUseNormalizedDistinctNames() {
        var score = scorer.score(
                List.of(" JAVA ", "java", "Data   Science"),
                List.of("Docker", " docker ", "JAVA"),
                List.of("java", " data science ", "DOCKER", "docker"),
                List.of(), List.of(), false).orElseThrow();

        assertThat(score.matchedRequiredSkills()).containsExactly("data science", "java");
        assertThat(score.matchedOptionalSkills()).containsExactly("docker");
        assertThat(score.skillPoints()).isEqualByComparingTo("70.00");
        assertThat(score.score()).isEqualByComparingTo("70.00");
    }

    @Test
    void partialRequiredMatchAndOptionalMatchUseThreeToOneWeighting() {
        var score = scorer.score(List.of("java", "sql"), List.of("docker", "git"),
                List.of("java", "docker"), List.of(), List.of(), false).orElseThrow();

        assertThat(score.matchedRequiredSkills()).containsExactly("java");
        assertThat(score.matchedOptionalSkills()).containsExactly("docker");
        assertThat(score.skillPoints()).isEqualByComparingTo("35.00");
    }

    @Test
    void emptyInterestsDoNotRedistributePointsAndOnlyAcceptedFlagAddsConnectionPoints() {
        var disconnected = scorer.score(List.of("java"), List.of(), List.of("java"),
                List.of("ai"), List.of(), false).orElseThrow();
        var connected = scorer.score(List.of("java"), List.of(), List.of("java"),
                List.of(), List.of("ai"), true).orElseThrow();

        assertThat(disconnected.interestPoints()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(disconnected.connectionPoints()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(disconnected.score()).isEqualByComparingTo("70.00");
        assertThat(connected.interestPoints()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(connected.connectionPoints()).isEqualByComparingTo("10.00");
        assertThat(connected.score()).isEqualByComparingTo("80.00");
    }

    @Test
    void zeroRequiredSkillsOrZeroRequiredMatchesAreIneligible() {
        assertThat(scorer.score(List.of(), List.of("java"), List.of("java"),
                List.of(), List.of(), false)).isEmpty();
        assertThat(scorer.score(List.of("sql"), List.of("java"), List.of("java"),
                List.of(), List.of(), false)).isEmpty();
    }

    @Test
    void displayUsesHalfUpWhileRawTotalRetainsRankingPrecision() {
        var score = scorer.score(List.of("a", "b", "c"), List.of(), List.of("a"),
                List.of("one", "two", "three"), List.of("one"), false).orElseThrow();

        assertThat(score.rawTotal().scale()).isGreaterThanOrEqualTo(ProjectRecommendationScorer.DISPLAY_SCALE);
        assertThat(score.skillPoints()).isEqualByComparingTo("23.33");
        assertThat(score.interestPoints()).isEqualByComparingTo("6.67");
        assertThat(score.score()).isEqualByComparingTo("30.00");
    }

    @Test
    void rawTotalsRemainDistinctWhenDisplayedTotalsTie() {
        List<String> required = java.util.stream.IntStream.range(0, 12)
                .mapToObj(index -> "required " + index).toList();
        List<String> optional = List.of("optional 0", "optional 1");
        List<String> creatorInterests = java.util.stream.IntStream.range(0, 29)
                .mapToObj(index -> "interest " + index).toList();
        var lower = scorer.score(required, optional,
                List.of("required 0", "optional 0"), creatorInterests,
                creatorInterests.subList(0, 8), false).orElseThrow();
        var higher = scorer.score(required, optional,
                List.of("required 0", "required 1", "optional 0"), creatorInterests,
                List.of(), false).orElseThrow();

        assertThat(lower.score()).isEqualByComparingTo("12.89");
        assertThat(higher.score()).isEqualByComparingTo("12.89");
        assertThat(higher.rawTotal()).isGreaterThan(lower.rawTotal());
    }
}
