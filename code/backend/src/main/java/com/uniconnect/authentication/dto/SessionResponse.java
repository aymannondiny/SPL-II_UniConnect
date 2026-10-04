package com.uniconnect.authentication.dto;

import java.time.Instant;
import java.util.UUID;

public record SessionResponse(UUID sessionId, String tokenType, String accessToken,
        String refreshToken, Instant accessExpiresAt, Instant expiresAt) {
    @Override public String toString() { return "SessionResponse[REDACTED]"; }
}
