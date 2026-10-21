package com.uniconnect.project.dto;

import java.util.List;

public record ProjectRecommendationResponse(long userId, String displayName, String profilePhotoUrl,
        String departmentName, List<String> matchedRequiredSkills, List<String> matchedOptionalSkills) {}
