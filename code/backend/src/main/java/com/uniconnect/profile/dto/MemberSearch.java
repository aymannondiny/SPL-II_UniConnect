package com.uniconnect.profile.dto;
import com.uniconnect.shared.security.PlatformRole;
import java.util.List;
public record MemberSearch(String name, PlatformRole role, Long departmentId, Long programmeId,
        List<String> skills, Integer yearOfStudy, Boolean projectAvailable, Boolean mentorshipAvailable,
        String company, String industry, Integer graduationYear, String sort, int page, int size) {}
