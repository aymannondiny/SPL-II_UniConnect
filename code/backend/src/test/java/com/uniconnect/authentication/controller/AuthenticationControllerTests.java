package com.uniconnect.authentication.controller;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.service.RegistrationService;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.ApiAccessDeniedHandler;
import com.uniconnect.shared.security.ApiAuthenticationEntryPoint;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;



import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(AuthenticationController.class)
@Import(SecurityConfig.class)
class AuthenticationControllerTests {
    @MockitoBean
    private com.uniconnect.authentication.service.SessionService sessions;

    @MockitoBean
    private com.uniconnect.shared.security.SecurityErrorResponseWriter errorWriter;


    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private RegistrationService registrationService;

    @MockitoBean
    private ApiAuthenticationEntryPoint apiAuthenticationEntryPoint;

    @MockitoBean
    private ApiAccessDeniedHandler apiAccessDeniedHandler;

    @Test
    void registersUserAndReturnsCreatedResponse() throws Exception {
        User user = User.register(
                "Ayman",
                "ayman@iut-dhaka.edu",
                "encoded-password",
                PlatformRole.STUDENT
        );

        when(registrationService.register(
                eq("Ayman"),
                eq("ayman@iut-dhaka.edu"),
                eq("plain-password"),
                eq(PlatformRole.STUDENT)
        )).thenReturn(user);

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType("application/json")
                        .content("""
                                {
                                  "fullName": "Ayman",
                                  "email": "ayman@iut-dhaka.edu",
                                  "password": "plain-password",
                                  "platformRole": "STUDENT"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.fullName").value("Ayman"))
                .andExpect(jsonPath("$.email").value("ayman@iut-dhaka.edu"))
                .andExpect(jsonPath("$.platformRole").value("STUDENT"))
                .andExpect(jsonPath("$.accountStatus").value("PENDING_VERIFICATION"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void rejectsInvalidRegistrationRequest() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType("application/json")
                        .content("""
                            {
                              "fullName": "",
                              "email": "not-an-email",
                              "password": "short",
                              "platformRole": null
                            }
                            """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
                .andExpect(jsonPath("$.message")
                        .value("Request validation failed."))
                .andExpect(jsonPath("$.path")
                        .value("/api/v1/auth/register"))
                .andExpect(jsonPath("$.timestamp").exists())
                .andExpect(jsonPath("$.fieldErrors").isArray())
                .andExpect(jsonPath("$.fieldErrors").isNotEmpty())
                .andExpect(jsonPath(
                        "$.fieldErrors[?(@.field == 'fullName')]"
                ).exists())
                .andExpect(jsonPath(
                        "$.fieldErrors[?(@.field == 'email')]"
                ).exists())
                .andExpect(jsonPath(
                        "$.fieldErrors[?(@.field == 'password')]"
                ).exists())
                .andExpect(jsonPath(
                        "$.fieldErrors[?(@.field == 'platformRole')]"
                ).exists());
    }

    @Test
    void rejectsSystemAdminRegistration() throws Exception {
        when(registrationService.register(
                eq("Admin"),
                eq("admin@iut-dhaka.edu"),
                eq("plain-password"),
                eq(PlatformRole.SYSTEM_ADMIN)
        )).thenThrow(new BadRequestException(
                "INVALID_REGISTRATION_ROLE",
                "SYSTEM_ADMIN cannot be selected during public registration"
        ));

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType("application/json")
                        .content("""
                            {
                              "fullName": "Admin",
                              "email": "admin@iut-dhaka.edu",
                              "password": "plain-password",
                              "platformRole": "SYSTEM_ADMIN"
                            }
                            """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.code")
                        .value("INVALID_REGISTRATION_ROLE"))
                .andExpect(jsonPath("$.message")
                        .value("SYSTEM_ADMIN cannot be selected during public registration"))
                .andExpect(jsonPath("$.path")
                        .value("/api/v1/auth/register"))
                .andExpect(jsonPath("$.fieldErrors").isEmpty());
    }
}
