package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.shared.security.PlatformRole;
import java.util.List;

public record MentorSummaryResponse(
        Long mentorProfileId,
        Long userId,
        String fullName,
        PlatformRole role,
        String departmentName,
        Integer yearOfStudy,
        Integer graduationYear,
        String profilePhotoUrl,
        MentorStatus status,
        List<String> expertiseTopics
) {}
