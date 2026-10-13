package com.uniconnect.mentorship.dto;

import jakarta.validation.constraints.Size;

public record EnrollSlotRequest(
        @Size(max = 300, message = "Join message must be at most 300 characters")
        String joinMessage,

        @Size(max = 1000, message = "Learning goal must be at most 1000 characters")
        String learningGoal
) {}
