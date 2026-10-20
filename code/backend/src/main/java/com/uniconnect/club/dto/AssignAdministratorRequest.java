package com.uniconnect.club.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record AssignAdministratorRequest(@NotNull @Positive Long userId) {}
