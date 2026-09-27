package com.uniconnect.authentication.dto;

import com.uniconnect.shared.security.PlatformRole;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank
        String fullName,

        @NotBlank
        @Email
        String email,

        @NotBlank
        @Size(min = 8, max = 72)
        String password,

        @NotNull
        PlatformRole platformRole
) {
}
