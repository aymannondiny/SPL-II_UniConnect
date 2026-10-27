package com.uniconnect.authentication.service;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class VerificationCodeGenerator {
    private static final int CODE_SPACE = 1_000_000;
    private final SecureRandom random;

    public VerificationCodeGenerator() {
        this(new SecureRandom());
    }

    VerificationCodeGenerator(SecureRandom random) {
        this.random = random;
    }

    public String generateCode() {
        return String.format(Locale.ROOT, "%06d", random.nextInt(CODE_SPACE));
    }

    public String generateSalt() {
        byte[] salt = new byte[32];
        random.nextBytes(salt);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(salt);
    }

    public String digest(long userId, String normalizedEmail, String salt, String code) {
        MessageDigest digest = sha256();
        digest.update(Base64.getUrlDecoder().decode(salt));
        digest.update(ByteBuffer.allocate(Long.BYTES).putLong(userId).array());
        digest.update(normalizedEmail.getBytes(StandardCharsets.UTF_8));
        digest.update((byte) 0);
        digest.update(code.getBytes(StandardCharsets.US_ASCII));
        return HexFormat.of().formatHex(digest.digest());
    }

    public boolean matches(long userId, String normalizedEmail, String salt,
            String storedDigest, String candidateCode) {
        byte[] expected = HexFormat.of().parseHex(storedDigest);
        byte[] actual = HexFormat.of().parseHex(digest(userId, normalizedEmail, salt, candidateCode));
        return MessageDigest.isEqual(expected, actual);
    }

    private MessageDigest sha256() {
        try {
            return MessageDigest.getInstance("SHA-256");
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable");
        }
    }
}
