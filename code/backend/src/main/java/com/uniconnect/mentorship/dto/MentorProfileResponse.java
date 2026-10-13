package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.shared.security.PlatformRole;
import java.time.LocalDateTime;
import java.util.List;

public record MentorProfileResponse(
        Long mentorProfileId,
        Long userId,
        String fullName,
        PlatformRole role,
        String departmentName,
        Integer yearOfStudy,
        Integer graduationYear,
        String profilePhotoUrl,
        String mentoringBio,
        MentorStatus status,
        List<ExpertiseResponse> expertise,
        LocalDateTime registeredAt,
        LocalDateTime updatedAt
) {}
