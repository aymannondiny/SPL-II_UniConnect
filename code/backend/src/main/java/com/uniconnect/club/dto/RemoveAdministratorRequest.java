package com.uniconnect.club.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RemoveAdministratorRequest(@NotBlank @Size(max = 1000) String reason,
        @AssertTrue Boolean confirmed) {}
