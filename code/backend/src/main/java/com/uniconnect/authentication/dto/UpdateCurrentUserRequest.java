package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCurrentUserRequest(
        @NotBlank @Size(max = 100) String fullName
) {
    @Override public String toString() { return "UpdateCurrentUserRequest[REDACTED]"; }
}
