package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.BadRequestException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/** New-password validation only: existing accounts can still log in. */
public final class PasswordPolicy {
    private static final List<String> COMMON = List.of(
            "password", "qwerty", "letmein", "welcome", "admin",
            "iloveyou", "uniconnect", "abcde");
    private static final List<String> SEQUENCES = List.of(
            "abcdefghijklmnopqrstuvwxyz", "0123456789",
            "qwertyuiop", "asdfghjkl", "zxcvbnm");
    private static final Pattern DIGITS = Pattern.compile("^[0-9]+$");
    private static final Pattern REPEATED = Pattern.compile("(.)\\1{3,}");

    private PasswordPolicy() { }

    public static void validate(String password) {
        if (password == null || password.length() < 8 || password.length() > 72
                || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw new BadRequestException("INVALID_PASSWORD",
                    "Use 8–72 characters and at most 72 UTF-8 bytes.");
        }
        if (isPredictable(password)) {
            throw new BadRequestException("INVALID_PASSWORD",
                    "Avoid common words, sequences, repeated patterns and numbers only.");
        }
    }

    private static boolean isPredictable(String password) {
        String lower = password.toLowerCase(Locale.ROOT);
        String normalized = lower.replace('0', 'o').replace('1', 'i')
                .replace('3', 'e').replace('4', 'a').replace('5', 's')
                .replace('7', 't').replace('@', 'a').replace('$', 's');
        if (password.isBlank() || DIGITS.matcher(password).matches()
                || REPEATED.matcher(password).find()
                || COMMON.stream().anyMatch(normalized::contains)) return true;
        for (int length = 1; length <= password.length() / 2; length++) {
            if (password.substring(0, length).repeat(password.length() / length)
                    .equals(password)) return true;
        }
        for (String sequence : SEQUENCES) {
            String reversed = new StringBuilder(sequence).reverse().toString();
            for (int index = 0; index + 4 <= lower.length(); index++) {
                String part = lower.substring(index, index + 4);
                if (sequence.contains(part) || reversed.contains(part)) return true;
            }
        }
        return false;
    }
}
