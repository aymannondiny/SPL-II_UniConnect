package com.uniconnect.project.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.TreeSet;
import org.springframework.stereotype.Component;

@Component
public class ProjectRecommendationScorer {
    static final int CALCULATION_SCALE = 16;
    static final int DISPLAY_SCALE = 2;
    private static final BigDecimal SKILL_MAXIMUM = BigDecimal.valueOf(70);
    private static final BigDecimal INTEREST_MAXIMUM = BigDecimal.valueOf(20);
    private static final BigDecimal CONNECTION_MAXIMUM = BigDecimal.TEN;

    public record Score(
            BigDecimal rawTotal,
            BigDecimal score,
            BigDecimal skillPoints,
            BigDecimal interestPoints,
            BigDecimal connectionPoints,
            List<String> matchedRequiredSkills,
            List<String> matchedOptionalSkills,
            List<String> matchedInterests,
            boolean directlyConnected
    ) {}

    public Optional<Score> score(
            Collection<String> requiredProjectSkills,
            Collection<String> optionalProjectSkills,
            Collection<String> candidateSkills,
            Collection<String> creatorInterests,
            Collection<String> candidateInterests,
            boolean directlyConnected
    ) {
        Set<String> required = normalized(requiredProjectSkills);
        if (required.isEmpty()) return Optional.empty();

        Set<String> optional = normalized(optionalProjectSkills);
        optional.removeAll(required);
        Set<String> availableSkills = normalized(candidateSkills);
        List<String> matchedRequired = intersection(required, availableSkills);
        if (matchedRequired.isEmpty()) return Optional.empty();
        List<String> matchedOptional = intersection(optional, availableSkills);

        int totalSkillWeight = required.size() * 3 + optional.size();
        int matchedSkillWeight = matchedRequired.size() * 3 + matchedOptional.size();
        BigDecimal rawSkillPoints = points(SKILL_MAXIMUM, matchedSkillWeight, totalSkillWeight);

        Set<String> normalizedCreatorInterests = normalized(creatorInterests);
        Set<String> normalizedCandidateInterests = normalized(candidateInterests);
        List<String> matchedInterests = intersection(normalizedCreatorInterests, normalizedCandidateInterests);
        BigDecimal rawInterestPoints = normalizedCreatorInterests.isEmpty() || normalizedCandidateInterests.isEmpty()
                ? BigDecimal.ZERO
                : points(INTEREST_MAXIMUM, matchedInterests.size(), normalizedCreatorInterests.size());
        BigDecimal rawConnectionPoints = directlyConnected ? CONNECTION_MAXIMUM : BigDecimal.ZERO;
        BigDecimal rawTotal = rawSkillPoints.add(rawInterestPoints).add(rawConnectionPoints);

        return Optional.of(new Score(rawTotal, display(rawTotal), display(rawSkillPoints),
                display(rawInterestPoints), display(rawConnectionPoints), matchedRequired, matchedOptional,
                matchedInterests, directlyConnected));
    }

    public String normalizeName(String value) {
        return normalize(value);
    }

    private BigDecimal points(BigDecimal maximum, int numerator, int denominator) {
        return maximum.multiply(BigDecimal.valueOf(numerator))
                .divide(BigDecimal.valueOf(denominator), CALCULATION_SCALE, RoundingMode.HALF_UP);
    }

    private BigDecimal display(BigDecimal value) {
        return value.setScale(DISPLAY_SCALE, RoundingMode.HALF_UP);
    }

    private List<String> intersection(Set<String> first, Set<String> second) {
        return first.stream().filter(second::contains).toList();
    }

    private Set<String> normalized(Collection<String> values) {
        Set<String> result = new TreeSet<>();
        if (values == null) return result;
        values.stream().filter(value -> value != null && !value.isBlank())
                .map(this::normalize).filter(value -> !value.isEmpty()).forEach(result::add);
        return result;
    }

    private String normalize(String value) {
        return value.strip().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
    }
}
