package com.uniconnect.authentication.dto;

import com.uniconnect.shared.security.PlatformRole;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

        @NotBlank
        @Schema(
                description = "User's full name",
                example = "Ayman Nondiny"
        )
        String fullName,

        @NotBlank
        @Email
        @Schema(
                description = "IUT email address. Must end with @iut-dhaka.edu",
                example = "ayman123@iut-dhaka.edu"
        )
        String email,

        @NotBlank
        @Size(min = 8, max = 72)
        @Schema(
                description = "Account password",
                example = "StrongPass123"
        )
        String password,

        @NotNull
        @Schema(
                description = "Public registration role. Only STUDENT or ALUMNI are allowed.",
                allowableValues = {"STUDENT", "ALUMNI"},
                example = "STUDENT"
        )
        PlatformRole platformRole
) {
}
