package com.uniconnect.discovery.dto;

import java.util.List;

public record CandidateSearch(
        List<String> requiredSkills,
        List<String> optionalSkills,
        Long departmentId,
        Integer yearOfStudy,
        Boolean projectAvailable,
        String sort,
        int page,
        int size
) {}
