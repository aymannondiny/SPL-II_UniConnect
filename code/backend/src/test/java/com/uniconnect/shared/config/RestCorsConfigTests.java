package com.uniconnect.shared.config;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class RestCorsConfigTests {

    private final RestCorsConfig config = new RestCorsConfig();

    @Test
    void emptyConfigurationAllowsNoCrossOriginRequests() {
        var source = config.restCorsConfigurationSource("");
        var request = new MockHttpServletRequest("OPTIONS", "/api/v1/auth/register");

        var cors = source.getCorsConfiguration(request);

        assertThat(cors).isNotNull();
        assertThat(cors.checkOrigin("http://localhost:3000")).isNull();
    }

    @Test
    void originsAreExactAndRestConfigurationDoesNotApplyToWebSockets() {
        var source = config.restCorsConfigurationSource("http://localhost:3000");
        var apiRequest = new MockHttpServletRequest("OPTIONS", "/api/v1/auth/register");
        var socketRequest = new MockHttpServletRequest("GET", "/ws/chat");

        var cors = source.getCorsConfiguration(apiRequest);

        assertThat(cors).isNotNull();
        assertThat(cors.checkOrigin("http://localhost:3000")).isEqualTo("http://localhost:3000");
        assertThat(cors.checkOrigin("http://127.0.0.1:3000")).isNull();
        assertThat(cors.getAllowCredentials()).isFalse();
        assertThat(source.getCorsConfiguration(socketRequest)).isNull();
    }

    @Test
    void wildcardOriginIsRejected() {
        assertThatThrownBy(() -> config.restCorsConfigurationSource("https://*.example.edu"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("REST CORS requires exact allowed origins");
    }
}
