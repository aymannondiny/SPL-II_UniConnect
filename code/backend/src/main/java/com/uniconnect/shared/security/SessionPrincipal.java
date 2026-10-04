package com.uniconnect.shared.security;

import java.util.UUID;

public record SessionPrincipal(UUID sessionId, Long userId, PlatformRole platformRole) { }
