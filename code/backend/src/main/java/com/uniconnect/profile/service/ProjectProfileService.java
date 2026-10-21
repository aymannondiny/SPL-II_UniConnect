package com.uniconnect.profile.service;

import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.service.ConnectionQueryService;
import com.uniconnect.profile.domain.PersonalProfile;
import com.uniconnect.profile.domain.Skill;
import com.uniconnect.profile.repository.PersonalProfileRepository;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Profile-owned read contracts used by Project Teammate Finder. */
@Service
@Transactional(propagation = Propagation.MANDATORY, readOnly = true)
public class ProjectProfileService {
    public record DepartmentSummary(long id, String code, String name) {}
    public record CandidateProfile(long userId, String displayName, String profilePhotoUrl,
            String departmentName, List<String> skills) {}
    private final PersonalProfileRepository profiles;
    private final ConnectionQueryService connections;
    public ProjectProfileService(PersonalProfileRepository profiles, ConnectionQueryService connections) {
        this.profiles = profiles; this.connections = connections;
    }

    public Map<Long, DepartmentSummary> departments(Collection<Long> userIds) {
        if (userIds.isEmpty()) return Map.of();
        var result = new LinkedHashMap<Long, DepartmentSummary>();
        profiles.findAcademicProfiles(userIds).forEach(profile -> {
            var department = profile.getProgrammeDegree().getProgramme().getDepartment();
            result.put(profile.getUser().getUserId(),
                    new DepartmentSummary(department.getId(), department.getCode(), department.getName()));
        });
        return result;
    }

    public Set<Long> userIdsInDepartment(long departmentId) {
        return new LinkedHashSet<>(profiles.findUserIdsByDepartment(departmentId));
    }

    /** Returns only opted-in students whose profile details are visible to this viewer. */
    public List<CandidateProfile> availableProjectCandidates(long viewerId, Collection<Long> excludedUserIds,
            Collection<String> relevantSkills) {
        if (relevantSkills.isEmpty()) return List.of();
        var visibleUsers = connections.relationships(viewerId).entrySet().stream()
                .filter(entry -> entry.getValue().status() == ConnectionStatus.ACCEPTED)
                .map(Map.Entry::getKey).collect(Collectors.toCollection(LinkedHashSet::new));
        // The caller is excluded from results, but including the viewer makes the visibility
        // predicate valid even when they have no accepted connections.
        visibleUsers.add(viewerId);
        return profiles.findAvailableProjectCandidates(excludedUserIds, visibleUsers, relevantSkills).stream().map(profile -> {
            var department = profile.getProgrammeDegree().getProgramme().getDepartment();
            var skills = profile.getSkills().stream().map(Skill::getName).sorted(String.CASE_INSENSITIVE_ORDER).toList();
            return new CandidateProfile(profile.getUser().getUserId(), profile.getUser().getFullName(),
                    profile.getProfilePhotoUrl(), department.getName(), skills);
        }).toList();
    }
}
