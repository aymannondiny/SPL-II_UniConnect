package com.uniconnect.profile.service;
import com.uniconnect.profile.dto.MemberSearch;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.validation.PageValidation;
import java.util.*;
import org.springframework.stereotype.Component;

@Component
public class MemberSearchValidation {
    public MemberSearch normalize(MemberSearch s) {
        if (s == null) throw invalid();
        PageValidation.check(s.page(), s.size());
        if (s.role() == PlatformRole.SYSTEM_ADMIN || s.sort() == null || !Set.of("NAME_ASC", "NAME_DESC").contains(s.sort())
                || (s.departmentId() != null && s.departmentId() <= 0) || (s.programmeId() != null && s.programmeId() <= 0)
                || (s.yearOfStudy() != null && (s.yearOfStudy() < 1 || s.yearOfStudy() > 20))
                || (s.graduationYear() != null && (s.graduationYear() < 1900 || s.graduationYear() > 2200))) throw invalid();
        List<String> skills = s.skills() == null ? List.of() : s.skills();
        if (skills.size() > 10) throw invalid();
        List<String> normalized = new ArrayList<>();
        for (String skill : skills) {
            String value = text(skill, 60);
            if (value == null) throw invalid();
            normalized.add(value.replaceAll("\\s+", " "));
        }
        return new MemberSearch(text(s.name(), 100), s.role(), s.departmentId(), s.programmeId(),
                normalized.stream().distinct().sorted().toList(), s.yearOfStudy(), s.projectAvailable(), s.mentorshipAvailable(),
                text(s.company(), 150), text(s.industry(), 100), s.graduationYear(), s.sort(), s.page(), s.size());
    }
    private String text(String value, int max) {
        if (value == null || value.isBlank()) return null;
        if (value.length() > max) throw invalid();
        return value.strip().toLowerCase(Locale.ROOT);
    }
    private BadRequestException invalid() { return new BadRequestException("INVALID_MEMBER_FILTER", "Invalid member search filters."); }
}
