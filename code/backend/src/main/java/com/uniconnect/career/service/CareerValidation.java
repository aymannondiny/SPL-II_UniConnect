package com.uniconnect.career.service;

import com.uniconnect.career.dto.CareerPostRequest;
import com.uniconnect.career.dto.CareerSkillRequest;
import com.uniconnect.shared.exception.BadRequestException;
import jakarta.validation.Validator;
import java.net.URI;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class CareerValidation {
    public record ValidatedPost(
            String title, String companyName, String description, String qualifications, String location,
            com.uniconnect.career.domain.EmploymentType employmentType,
            com.uniconnect.career.domain.WorkMode workMode, String salaryRange, String applicationUrl,
            String applicationEmail, LocalDate applicationDeadline, List<CareerSkillRequest> skills) {}

    private final Validator validator;

    public CareerValidation(Validator validator) { this.validator = validator; }

    public ValidatedPost post(CareerPostRequest request, LocalDate today) {
        if (request == null || !validator.validate(request).isEmpty()) throw invalid("Career post fields are invalid.");
        String url = url(request.applicationUrl());
        String email = optional(request.applicationEmail());
        if (email != null) email = email.toLowerCase(Locale.ROOT);
        if (url == null && email == null) throw invalid("At least one application URL or email is required.");
        if (request.applicationDeadline().isBefore(today)) {
            throw invalid("applicationDeadline must be today or later in Asia/Dhaka.");
        }
        var seen = new HashSet<String>();
        var skills = new ArrayList<CareerSkillRequest>();
        for (CareerSkillRequest skill : request.skills()) {
            String name = required(skill.name()).replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
            if (!seen.add(name)) throw invalid("Skill names must be unique within a post.");
            skills.add(new CareerSkillRequest(name, skill.required()));
        }
        return new ValidatedPost(required(request.title()), required(request.companyName()),
                required(request.description()), required(request.qualifications()), optional(request.location()),
                request.employmentType(), request.workMode(), optional(request.salaryRange()), url, email,
                request.applicationDeadline(), List.copyOf(skills));
    }

    public String note(String note) {
        String result = optional(note);
        if (result != null && result.length() > 1000) throw invalid("Saved note must not exceed 1000 characters.");
        return result;
    }

    public String location(String location) {
        String result = optional(location);
        if (result != null && result.length() > 200) throw invalid("Location must not exceed 200 characters.");
        return result == null ? null : result.toLowerCase(Locale.ROOT);
    }

    public String skill(String skill) {
        String result = optional(skill);
        if (result != null && result.length() > 60) throw invalid("Skill must not exceed 60 characters.");
        return result == null ? null : result.replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
    }

    private String required(String value) {
        String result = value == null ? "" : value.strip();
        if (result.isEmpty()) throw invalid("Required career post fields must not be blank.");
        return result;
    }

    private String optional(String value) { return value == null || value.isBlank() ? null : value.strip(); }

    private String url(String value) {
        String result = optional(value);
        if (result == null) return null;
        try {
            URI uri = URI.create(result);
            if (!"https".equalsIgnoreCase(uri.getScheme()) || uri.getHost() == null || uri.getUserInfo() != null) {
                throw new IllegalArgumentException();
            }
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("INVALID_APPLICATION_URL",
                    "Application URL must be an absolute HTTPS URL without credentials.");
        }
        return result;
    }

    private BadRequestException invalid(String message) {
        return new BadRequestException("INVALID_CAREER_REQUEST", message);
    }
}
