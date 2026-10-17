package com.uniconnect.shared.security;

import com.uniconnect.authentication.service.SessionService;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.http.HttpStatus;
import jakarta.servlet.FilterChain;

import static org.mockito.Mockito.*;

class SessionAuthenticationFilterTests {
    @Test
    void infrastructureFailureUsesApiErrorAndNeverContinuesUnauthenticated() throws Exception {
        var sessions = mock(SessionService.class);
        var entryPoint = mock(ApiAuthenticationEntryPoint.class);
        var writer = mock(SecurityErrorResponseWriter.class);
        var filter = new SessionAuthenticationFilter(sessions, entryPoint, writer);
        var request = new MockHttpServletRequest("GET", "/api/v1/auth/me");
        request.addHeader("Authorization", "Bearer " + "a".repeat(43));
        var response = new MockHttpServletResponse();
        var chain = mock(FilterChain.class);
        when(sessions.authenticate(anyString())).thenThrow(new IllegalStateException("private provider detail"));
        filter.doFilter(request, response, chain);
        verify(writer).write(request, response, HttpStatus.INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR", "An unexpected server error occurred.");
        verifyNoInteractions(chain, entryPoint);
    }
}
