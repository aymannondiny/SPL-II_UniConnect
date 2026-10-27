package com.uniconnect.authentication.service;

import java.security.SecureRandom;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class VerificationCodeGeneratorTests {
    @Test
    void samplesUniformSixDigitSpaceAndPreservesLeadingZeros() {
        SecureRandom random = new FixedSecureRandom(0, 999_999);
        var generator = new VerificationCodeGenerator(random);
        assertThat(generator.generateCode()).isEqualTo("000000");
        assertThat(generator.generateCode()).isEqualTo("999999");
    }

    @Test
    void digestIsBoundToAccountEmailSaltAndCode() {
        var generator = new VerificationCodeGenerator();
        String salt = generator.generateSalt();
        String digest = generator.digest(1L, "one@iut-dhaka.edu", salt, "012345");
        assertThat(generator.matches(1L, "one@iut-dhaka.edu", salt, digest, "012345")).isTrue();
        assertThat(generator.matches(2L, "one@iut-dhaka.edu", salt, digest, "012345")).isFalse();
        assertThat(generator.matches(1L, "two@iut-dhaka.edu", salt, digest, "012345")).isFalse();
        assertThat(generator.matches(1L, "one@iut-dhaka.edu", salt, digest, "112345")).isFalse();
    }

    private static final class FixedSecureRandom extends SecureRandom {
        private final int[] values;
        private int index;

        private FixedSecureRandom(int... values) {
            this.values = values;
        }

        @Override
        public int nextInt(int bound) {
            assertThat(bound).isEqualTo(1_000_000);
            return values[index++];
        }
    }
}
