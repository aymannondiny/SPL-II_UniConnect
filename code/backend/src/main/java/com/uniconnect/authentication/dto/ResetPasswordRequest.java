package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.*;

public record ResetPasswordRequest(@NotBlank @Size(max = 128) String token,
        @NotBlank @Size(min = 8, max = 72) String newPassword) {
    @Override public String toString() { return "ResetPasswordRequest[REDACTED]"; }
}
