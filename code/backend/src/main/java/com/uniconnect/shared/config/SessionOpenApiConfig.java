package com.uniconnect.shared.config;

import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@SecurityScheme(name = "sessionBearer", type = SecuritySchemeType.HTTP, scheme = "bearer",
        description = "Opaque access token returned by login or refresh; do not use the refresh token here.")
public class SessionOpenApiConfig { }
