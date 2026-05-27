package com.spl2.uniconnect.config;

import com.spl2.uniconnect.service.email.EmailService;
import org.mockito.Mockito;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;

/**
 * Test-specific configuration
 * Mocks external services like email
 */
@TestConfiguration
@Profile("test")
public class TestConfig {

    /**
     * Mock EmailService to prevent actual emails being sent during tests
     */
    @Bean
    @Primary
    public EmailService emailService() {
        return Mockito.mock(EmailService.class);
    }
}
