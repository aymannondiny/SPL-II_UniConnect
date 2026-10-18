package com.uniconnect.administration.dto;

import jakarta.validation.constraints.*;

public record AccountModerationRequest(@NotBlank @Size(max = 1000) String reason,
        @NotNull @AssertTrue Boolean confirm) {}
