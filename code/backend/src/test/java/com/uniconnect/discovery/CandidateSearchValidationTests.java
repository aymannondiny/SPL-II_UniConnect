package com.uniconnect.discovery;

import com.uniconnect.discovery.dto.CandidateSearch;
import com.uniconnect.discovery.service.CandidateSearchValidation;
import com.uniconnect.shared.exception.BadRequestException;
import java.util.List;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.*;

class CandidateSearchValidationTests {
    private final CandidateSearchValidation validation = new CandidateSearchValidation();

    @Test void normalizesAndDeduplicatesEachSkillList() {
        var result = validation.normalize(new CandidateSearch(List.of(" Java ", "java"),
                List.of(" SQL ", "sql"), 1L, 2, null, "NAME_ASC", 0, 20));
        assertThat(result.requiredSkills()).containsExactly("java");
        assertThat(result.optionalSkills()).containsExactly("sql");
        assertThat(result.projectAvailable()).isNull();
    }

    @Test void requiresARequiredSkillAndRejectsOverlap() {
        assertInvalid(new CandidateSearch(List.of(), List.of("sql"), null, null, null, "NAME_ASC", 0, 20));
        assertInvalid(new CandidateSearch(List.of(" Java "), List.of("java"), null, null, null, "NAME_ASC", 0, 20));
    }

    @Test void limitsCombinedDistinctSkillsToTen() {
        assertInvalid(new CandidateSearch(List.of("a", "b", "c", "d", "e", "f"),
                List.of("g", "h", "i", "j", "k"), null, null, null, "NAME_ASC", 0, 20));
    }

    @Test void validatesSortFiltersAndPageBounds() {
        assertInvalid(new CandidateSearch(List.of("java"), List.of(), null, null, null, "RECENT", 0, 20));
        assertInvalid(new CandidateSearch(List.of("java"), List.of(), 0L, null, null, "NAME_ASC", 0, 20));
        assertInvalid(new CandidateSearch(List.of("java"), List.of(), null, 0, null, "NAME_ASC", 0, 20));
        assertPageInvalid(new CandidateSearch(List.of("java"), List.of(), null, null, null, "NAME_ASC", -1, 20));
        assertPageInvalid(new CandidateSearch(List.of("java"), List.of(), null, null, null, "NAME_ASC", 0, 0));
        assertPageInvalid(new CandidateSearch(List.of("java"), List.of(), null, null, null, "NAME_ASC", 0, 51));
    }

    private void assertInvalid(CandidateSearch request) {
        assertThatThrownBy(() -> validation.normalize(request)).isInstanceOf(BadRequestException.class)
                .extracting("code").isEqualTo("INVALID_CANDIDATE_FILTER");
    }

    private void assertPageInvalid(CandidateSearch request) {
        assertThatThrownBy(() -> validation.normalize(request)).isInstanceOf(BadRequestException.class)
                .extracting("code").isEqualTo("INVALID_PAGE");
    }
}
