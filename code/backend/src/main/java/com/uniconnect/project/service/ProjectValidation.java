package com.uniconnect.project.service;

import com.uniconnect.project.dto.*;
import com.uniconnect.shared.exception.BadRequestException;
import java.time.LocalDate;
import java.util.*;
import org.springframework.stereotype.Component;

@Component
public class ProjectValidation {
    public record Input(String title, String description, int limit, String duration, String courseName,
            LocalDate deadline, List<ProjectSkillRequest> skills) {}

    public Input project(ProjectRequest request, LocalDate today) {
        if (request.teamSizeLimit() < 2 || request.teamSizeLimit() > 100)
            throw bad("INVALID_PROJECT_CAPACITY", "Project capacity must be between 2 and 100, including the creator.");
        if (request.applicationDeadline().isBefore(today))
            throw bad("INVALID_APPLICATION_DEADLINE", "Application deadline must be today or later in Asia/Dhaka.");
        var names = new HashSet<String>();
        var skills = new ArrayList<ProjectSkillRequest>();
        for (var skill : request.skills()) {
            String name = skill.name().strip().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
            if (!names.add(name)) throw bad("DUPLICATE_PROJECT_SKILL", "Project skill names must be unique.");
            skills.add(new ProjectSkillRequest(name, skill.required()));
        }
        if (skills.stream().noneMatch(ProjectSkillRequest::required))
            throw bad("REQUIRED_PROJECT_SKILL_MISSING", "At least one project skill must be required.");
        return new Input(request.title().strip(), request.description().strip(), request.teamSizeLimit(),
                clean(request.duration()), clean(request.courseName()), request.applicationDeadline(), skills);
    }

    public String message(ProjectApplicationRequest request) {
        return request == null ? null : clean(request.message());
    }

    public String skill(String value) {
        if (value == null || value.isBlank()) return null;
        String clean = value.strip().toLowerCase(Locale.ROOT);
        if (clean.length() > 60) throw bad("INVALID_PROJECT_SKILL", "Skill must not exceed 60 characters.");
        return clean;
    }
    private String clean(String value) { return value == null || value.isBlank() ? null : value.strip(); }
    private BadRequestException bad(String code, String message) { return new BadRequestException(code, message); }
}
