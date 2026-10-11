package com.uniconnect.club.service;
import com.uniconnect.shared.exception.BadRequestException;
import jakarta.validation.Validator;
import java.net.URI;
import org.springframework.stereotype.Component;
@Component
public class ClubValidation {
    private final Validator validator;
    public ClubValidation(Validator validator) { this.validator = validator; }
    public void check(Object request) {
        if (request == null || !validator.validate(request).isEmpty())
            throw new BadRequestException("INVALID_CLUB_REQUEST", "Required club fields are missing or invalid.");
    }
    public String optional(String value) { return value == null || value.isBlank() ? null : value.strip(); }
    public String logo(String value) {
        String result = optional(value);
        if (result == null) return null;
        try {
            var uri = URI.create(result);
            if (!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null || uri.getUserInfo() != null)
                throw new IllegalArgumentException();
        } catch (IllegalArgumentException invalid) {
            throw new BadRequestException("INVALID_LOGO_URL", "Logo URL must be an absolute HTTPS URL without credentials.");
        }
        return result;
    }
}
