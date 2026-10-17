package com.uniconnect.club.publication.service;

import com.uniconnect.club.publication.dto.EventRequest;
import com.uniconnect.shared.exception.BadRequestException;
import jakarta.validation.Validator;
import java.net.URI;
import java.time.LocalDateTime;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class PublicationValidation {
    private final Validator validator;
    public PublicationValidation(Validator validator) { this.validator = validator; }
    public void check(Object request) {
        if (request == null || !validator.validate(request).isEmpty())
            throw invalid("Required publication fields are missing or invalid.");
    }
    public void expiry(LocalDateTime expiry, LocalDateTime now) {
        if (expiry != null && !expiry.isAfter(now)) throw invalid("expiresAt must be in the future, or null.");
    }
    public void event(EventRequest request) {
        check(request);
        if (!request.endsAt().isAfter(request.startsAt())) throw invalid("endsAt must be later than startsAt.");
        if (request.registrationDeadline() != null && request.registrationDeadline().isAfter(request.startsAt()))
            throw invalid("Registration deadline must be at or before startsAt.");
        url(request.registrationUrl());
    }
    public String optional(String value) { return value == null || value.isBlank() ? null : value.strip(); }
    public String url(String value) {
        String result = optional(value);
        if (result == null) return null;
        try {
            var uri = URI.create(result);
            if (!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null || uri.getUserInfo() != null)
                throw new IllegalArgumentException();
        } catch (IllegalArgumentException bad) { throw invalid("Registration URL must be an absolute HTTPS URL without credentials."); }
        return result;
    }
    public String category(String value) {
        String result = optional(value);
        if (result != null && result.length() > 100) throw invalid("Category must not exceed 100 characters.");
        return result == null ? null : result.toLowerCase(Locale.ROOT);
    }
    public void range(LocalDateTime from, LocalDateTime before) {
        if (from != null && before != null && !before.isAfter(from)) throw invalid("publishedBefore must be later than publishedFrom.");
    }
    public void id(Long id) { if (id != null && id < 1) throw invalid("IDs must be positive."); }
    public BadRequestException invalid(String message) { return new BadRequestException("INVALID_PUBLICATION_REQUEST", message); }
}
