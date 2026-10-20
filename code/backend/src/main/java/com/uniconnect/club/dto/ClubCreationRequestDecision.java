package com.uniconnect.club.dto;

import jakarta.validation.constraints.Size;

public record ClubCreationRequestDecision(@Size(max = 1000) String reason) {}
