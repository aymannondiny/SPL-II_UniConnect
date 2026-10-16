package com.uniconnect.shared.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties =
        "uniconnect.cors.allowed-origins=http://localhost:3000,http://127.0.0.1:3000")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class SecurityConfigTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void protectedEndpointWithoutAuthenticationReturnsCanonical401()
            throws Exception {
        mockMvc.perform(get("/api/v1/test"))
                .andExpect(status().isUnauthorized())
                .andExpect(content().contentTypeCompatibleWith(
                        "application/json"
                ))
                .andExpect(jsonPath("$.status").value(401))
                .andExpect(jsonPath("$.error").value("Unauthorized"))
                .andExpect(jsonPath("$.code")
                        .value("AUTHENTICATION_REQUIRED"))
                .andExpect(jsonPath("$.message")
                        .value("Authentication is required to access this resource."))
                .andExpect(jsonPath("$.path").value("/api/v1/test"))
                .andExpect(jsonPath("$.fieldErrors").isArray());
    }

    @Test
    void allowedRegistrationPreflightReturnsCorsHeaders() throws Exception {
        mockMvc.perform(options("/api/v1/auth/register")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"))
                .andExpect(header().string("Access-Control-Allow-Methods", containsString("POST")))
                .andExpect(header().string("Access-Control-Allow-Headers", containsString("content-type")))
                .andExpect(header().doesNotExist("Access-Control-Allow-Credentials"));
    }

    @Test
    void allowedAuthenticatedRequestPreflightDoesNotRequireBearerToken() throws Exception {
        mockMvc.perform(options("/api/v1/profile/me")
                        .header("Origin", "http://127.0.0.1:3000")
                        .header("Access-Control-Request-Method", "GET")
                        .header("Access-Control-Request-Headers", "authorization"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://127.0.0.1:3000"))
                .andExpect(header().string("Access-Control-Allow-Headers", containsString("authorization")));
    }

    @Test
    void deniedOriginPreflightHasNoCorsPermissionHeaders() throws Exception {
        mockMvc.perform(options("/api/v1/auth/register")
                        .header("Origin", "https://untrusted.example")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "content-type"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
    }

    @Test
    void allowedOriginUnauthorizedResponseIncludesCorsHeader() throws Exception {
        mockMvc.perform(get("/api/v1/test")
                        .header("Origin", "http://localhost:3000"))
                .andExpect(status().isUnauthorized())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"))
                .andExpect(jsonPath("$.code").value("AUTHENTICATION_REQUIRED"));
    }

    @Test
    @WithMockUser(authorities = "STUDENT")
    void adminEndpointWithNonAdminAuthorityReturnsCanonical403()
            throws Exception {
        mockMvc.perform(get("/api/v1/admin/test"))
                .andExpect(status().isForbidden())
                .andExpect(content().contentTypeCompatibleWith(
                        "application/json"
                ))
                .andExpect(jsonPath("$.status").value(403))
                .andExpect(jsonPath("$.error").value("Forbidden"))
                .andExpect(jsonPath("$.code").value("ACCESS_DENIED"))
                .andExpect(jsonPath("$.message")
                        .value("You do not have permission to access this resource."))
                .andExpect(jsonPath("$.path")
                        .value("/api/v1/admin/test"))
                .andExpect(jsonPath("$.fieldErrors").isArray());
    }

    @Test
    @WithMockUser(authorities = "STUDENT")
    void allowedOriginForbiddenResponseIncludesCorsHeader() throws Exception {
        mockMvc.perform(get("/api/v1/admin/test")
                        .header("Origin", "http://localhost:3000"))
                .andExpect(status().isForbidden())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"))
                .andExpect(jsonPath("$.code").value("ACCESS_DENIED"));
    }

    @Test
    @WithMockUser(authorities = "SYSTEM_ADMIN")
    void adminEndpointWithSystemAdminAuthorityPassesSecurityBoundary()
            throws Exception {
        mockMvc.perform(get("/api/v1/admin/test"))
                .andExpect(status().isNotFound());
    }
}
