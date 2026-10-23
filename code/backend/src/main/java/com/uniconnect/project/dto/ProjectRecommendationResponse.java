package com.uniconnect.project.dto;

import java.math.BigDecimal;
import java.util.List;

public record ProjectRecommendationResponse(long userId, String displayName, String profilePhotoUrl,
        String departmentName, List<String> matchedRequiredSkills, List<String> matchedOptionalSkills,
        BigDecimal score, BigDecimal skillPoints, BigDecimal interestPoints, BigDecimal connectionPoints,
        List<String> matchedInterests, boolean directlyConnected) {}
