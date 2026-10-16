package com.uniconnect.club.dto;

import jakarta.validation.constraints.*;

public record ClubLifecycleRequest(@NotBlank @Size(max = 1000) String reason,
        @NotNull @AssertTrue Boolean confirm) {}
