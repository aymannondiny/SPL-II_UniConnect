package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.*;

public record ResetPasswordRequest(@NotBlank @Email @Size(max = 255) String email,
        @NotBlank @Pattern(regexp = "[0-9]{6}") String code,
        @NotBlank @Size(min = 8, max = 72) String newPassword) {
    @Override public String toString() { return "ResetPasswordRequest[REDACTED]"; }
}
