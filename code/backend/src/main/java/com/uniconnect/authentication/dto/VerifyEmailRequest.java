package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record VerifyEmailRequest(
        @NotBlank
        @Email
        @Size(max = 320)
        String email,

        @NotBlank
        @Pattern(regexp = "[0-9]{6}")
        String code
) {
    @Override
    public String toString() {
        return "VerifyEmailRequest[email=" + email + ", code=<redacted>]";
    }
}
