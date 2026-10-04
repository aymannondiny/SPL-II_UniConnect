package com.uniconnect.authentication.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RefreshSessionRequest(@NotBlank @Size(max = 128) String refreshToken) {
    @Override public String toString() { return "RefreshSessionRequest[REDACTED]"; }
}
