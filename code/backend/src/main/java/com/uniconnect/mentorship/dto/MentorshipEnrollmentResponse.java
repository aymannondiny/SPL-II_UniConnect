package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.EnrollmentStatus;
import java.time.LocalDateTime;

public record MentorshipEnrollmentResponse(
        Long enrollmentId,
        Long slotId,
        String slotTopic,
        Long menteeId,
        String menteeName,
        String joinMessage,
        String learningGoal,
        EnrollmentStatus status,
        LocalDateTime joinedAt,
        LocalDateTime leftAt
) {}
