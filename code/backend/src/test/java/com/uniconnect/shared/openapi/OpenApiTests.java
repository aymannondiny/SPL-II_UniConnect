package com.uniconnect.shared.openapi;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OpenApiTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void exposesOpenApiDocumentationWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("application/json"))
                .andExpect(jsonPath("$.openapi").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/register']").exists());
    }

    @Test
    void documentsRegistrationResponses() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath(
                        "$.paths['/api/v1/auth/register'].post.responses['201']"
                ).exists())
                .andExpect(jsonPath(
                        "$.paths['/api/v1/auth/register'].post.responses['400']"
                ).exists())
                .andExpect(jsonPath(
                        "$.paths['/api/v1/auth/register'].post.responses['409']"
                ).exists());
    }
    @Test
    void documentsVerificationEndpointsAndDeliveryFailure() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/v1/auth/verify-email'].post.responses['204']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/verify-email'].post.responses['400']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/resend-verification'].post.responses['202']").exists())
                .andExpect(jsonPath("$.paths['/api/v1/auth/register'].post.responses['503']").exists());
    }
}
