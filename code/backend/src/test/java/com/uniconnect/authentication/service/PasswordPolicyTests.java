package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.BadRequestException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class PasswordPolicyTests {
    @ParameterizedTest
    @ValueSource(strings = {"12345678", "987654321", "Password123!", "P@ssw0rd123!",
            "Qwerty123!xyz", "abcdEF12!xyZ", "zyxwV!293mR", "aaaaQ7!xyz",
            "Ab1!Ab1!Ab1!", "        ", "short"})
    void rejectsPredictablePasswords(String value) {
        assertThatThrownBy(() -> PasswordPolicy.validate(value))
                .isInstanceOf(BadRequestException.class);
    }

    @Test
    void acceptsUniquePasswordsAndPassphrasesWithoutTrimming() {
        assertThatCode(() -> PasswordPolicy.validate("R7!mQ2#vL9@x")).doesNotThrowAnyException();
        assertThatCode(() -> PasswordPolicy.validate(" reef violet lantern otter "))
                .doesNotThrowAnyException();
    }

    @Test
    void enforcesByteLimitAndNullSafety() {
        assertThatThrownBy(() -> PasswordPolicy.validate(null)).isInstanceOf(BadRequestException.class);
        assertThatThrownBy(() -> PasswordPolicy.validate("R7!mQ2#vL9@x" + "éøßñüç".repeat(5) + "é"))
                .isInstanceOf(BadRequestException.class);
        assertThatCode(() -> PasswordPolicy.validate("R7!mQ2#vL9@x" + "éøßñüç".repeat(5)))
                .doesNotThrowAnyException();
    }
}
