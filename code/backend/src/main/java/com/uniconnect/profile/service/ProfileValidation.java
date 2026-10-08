package com.uniconnect.profile.service;

import com.uniconnect.shared.exception.BadRequestException;
import jakarta.validation.Validator;
import java.net.URI;
import java.util.*;
import org.springframework.stereotype.Component;

@Component
public class ProfileValidation {
    private final Validator validator;
    public ProfileValidation(Validator validator) { this.validator = validator; }
    public void validate(Object request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw new BadRequestException("VALIDATION_FAILED", "Request validation failed.");
        }
    }
    public String required(String value) {
        String result = value.strip();
        if (result.isBlank()) throw new BadRequestException("VALIDATION_FAILED", "A required value is blank.");
        return result;
    }
    public String optional(String value) { return value == null || value.isBlank() ? null : value.strip(); }
    public String code(String value) { return required(value).toUpperCase(Locale.ROOT); }
    public Set<String> names(List<String> values) {
        Set<String> result = new TreeSet<>();
        values.forEach(value -> result.add(required(value).replaceAll("\\s+", " ").toLowerCase(Locale.ROOT)));
        return result;
    }
    public String url(String value, boolean linkedin) {
        String result = optional(value);
        if (result == null) return null;
        try {
            URI uri = URI.create(result);
            String host = uri.getHost();
            if (!("https".equalsIgnoreCase(uri.getScheme()) || "http".equalsIgnoreCase(uri.getScheme()))
                    || host == null || uri.getUserInfo() != null
                    || (linkedin && !(host.equalsIgnoreCase("linkedin.com") || host.toLowerCase(Locale.ROOT).endsWith(".linkedin.com")))) {
                throw new IllegalArgumentException();
            }
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("INVALID_PROFILE_URL", "Use an absolute HTTP(S) URL without credentials; LinkedIn links must use linkedin.com.");
        }
        return result;
    }
}
