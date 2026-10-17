package com.uniconnect.profile;

import com.uniconnect.profile.service.ProfileValidation;
import com.uniconnect.shared.exception.BadRequestException;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class ProfileValidationTests {
    @Test
    void rejectsUnsafeAndMisleadingUrls() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var validation = new ProfileValidation(factory.getValidator());
            for (String url : new String[]{"javascript:alert(1)", "//example.com/photo", "https://user:password@example.com/photo"}) {
                assertThatThrownBy(() -> validation.url(url, false)).isInstanceOf(BadRequestException.class);
            }
            assertThatThrownBy(() -> validation.url("https://notlinkedin.com/in/x", true)).isInstanceOf(BadRequestException.class);
            assertThat(validation.url("https://bd.linkedin.com/in/x", true)).isEqualTo("https://bd.linkedin.com/in/x");
            assertThat(validation.url("  ", false)).isNull();
        }
    }
}
