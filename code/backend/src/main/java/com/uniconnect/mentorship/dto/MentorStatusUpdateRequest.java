package com.uniconnect.mentorship.dto;

import com.uniconnect.mentorship.domain.MentorStatus;
import jakarta.validation.constraints.NotNull;

public record MentorStatusUpdateRequest(
        @NotNull(message = "Status is required")
        MentorStatus status
) {}
