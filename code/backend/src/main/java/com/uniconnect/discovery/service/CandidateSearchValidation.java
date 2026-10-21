package com.uniconnect.discovery.service;

import com.uniconnect.discovery.dto.CandidateSearch;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.validation.PageValidation;
import java.util.*;
import org.springframework.stereotype.Component;

@Component
public class CandidateSearchValidation {
    private static final Set<String> SORTS = Set.of("NAME_ASC", "NAME_DESC");

    public CandidateSearch normalize(CandidateSearch request) {
        if (request == null) throw invalid("Candidate search criteria are required.");
        PageValidation.check(request.page(), request.size());
        if (request.sort() == null || !SORTS.contains(request.sort())
                || request.departmentId() != null && request.departmentId() <= 0
                || request.yearOfStudy() != null && (request.yearOfStudy() < 1 || request.yearOfStudy() > 20))
            throw invalid("Invalid candidate search filters.");

        List<String> required = normalizeSkills(request.requiredSkills());
        List<String> optional = normalizeSkills(request.optionalSkills());
        if (required.isEmpty()) throw invalid("At least one required skill is required.");
        if (required.size() + optional.size() > 10)
            throw invalid("Candidate searches support at most 10 required and optional skills combined.");
        if (!Collections.disjoint(required, optional))
            throw invalid("A skill cannot be both required and optional.");

        return new CandidateSearch(required, optional, request.departmentId(), request.yearOfStudy(),
                request.projectAvailable(), request.sort(), request.page(), request.size());
    }

    private List<String> normalizeSkills(List<String> skills) {
        if (skills == null) return List.of();
        var normalized = new TreeSet<String>();
        for (String skill : skills) {
            if (skill == null || skill.isBlank() || skill.length() > 60)
                throw invalid("Skills must contain 1–60 characters.");
            normalized.add(skill.strip().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT));
        }
        return List.copyOf(normalized);
    }

    private BadRequestException invalid(String message) {
        return new BadRequestException("INVALID_CANDIDATE_FILTER", message);
    }
}
