package com.uniconnect.profile.service;

import com.uniconnect.profile.repository.PersonalProfileRepository;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Profile-owned read contract for current creator departments. */
@Service
@Transactional(propagation = Propagation.MANDATORY, readOnly = true)
public class ProjectProfileService {
    public record DepartmentSummary(long id, String code, String name) {}
    private final PersonalProfileRepository profiles;
    public ProjectProfileService(PersonalProfileRepository profiles) { this.profiles = profiles; }

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
}
