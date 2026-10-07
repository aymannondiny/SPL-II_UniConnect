package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.*;

public record ForgotPasswordRequest(@NotBlank @Email @Size(max = 320) String email) {
    @Override public String toString() { return "ForgotPasswordRequest[REDACTED]"; }
}
