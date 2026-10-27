package com.uniconnect.profile.service;

import com.uniconnect.profile.domain.AlumniProfile;
import com.uniconnect.profile.domain.PersonalProfile;
import com.uniconnect.profile.domain.ProfileVisibility;
import com.uniconnect.profile.domain.Skill;
import com.uniconnect.profile.domain.StudentProfile;
import com.uniconnect.profile.repository.PersonalProfileRepository;
import com.uniconnect.profile.repository.SkillRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.List;
import java.util.Set;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ProfileQueryService {

    public record SkillReference(long id, String name) {}

    public record AcademicSummary(
            String departmentName,
            Integer yearOfStudy,
            Integer graduationYear,
            String profilePhotoUrl
    ) {}

    private final PersonalProfileRepository profiles;
    private final SkillRepository skills;

    public ProfileQueryService(PersonalProfileRepository profiles, SkillRepository skills) {
        this.profiles = profiles;
        this.skills = skills;
    }

    @Transactional(readOnly = true)
    public Optional<PersonalProfile> findByUserId(long userId) {
        return profiles.findByUserUserId(userId);
    }

    @Transactional(readOnly = true)
    public Optional<Integer> findStudentYearOfStudy(long userId) {
        return profiles.findByUserUserId(userId)
                .filter(StudentProfile.class::isInstance)
                .map(p -> ((StudentProfile) p).getYearOfStudy());
    }

    @Transactional(readOnly = true)
    public Optional<AcademicSummary> findAcademicSummary(long userId) {
        return findAcademicSummary(userId, userId, true);
    }

    @Transactional(readOnly = true)
    public Optional<AcademicSummary> findAcademicSummary(long userId, Long viewerId, boolean areConnected) {
        return profiles.findAcademicProfiles(List.of(userId)).stream().findFirst()
                .map(p -> academicSummary(p, viewerId, areConnected));
    }

    @Transactional(readOnly = true)
    public Map<Long, AcademicSummary> findAcademicSummaries(
            Collection<Long> userIds, Long viewerId, Set<Long> connectedUserIds) {
        Map<Long, AcademicSummary> result = new LinkedHashMap<>();
        if (userIds.isEmpty()) return result;
        for (PersonalProfile profile : profiles.findAcademicProfiles(userIds)) {
            Long userId = profile.getUser().getUserId();
            result.put(userId, academicSummary(profile, viewerId, connectedUserIds.contains(userId)));
        }
        return result;
    }

    private AcademicSummary academicSummary(PersonalProfile p, Long viewerId, boolean areConnected) {
        long userId = p.getUser().getUserId();
        boolean visible = viewerId != null && (viewerId.equals(userId)
                || p.getDetailsVisibility() == ProfileVisibility.ALL_MEMBERS
                || (areConnected && p.getDetailsVisibility() == ProfileVisibility.CONNECTIONS_ONLY));
        String department = visible && p.getProgrammeDegree() != null
                && p.getProgrammeDegree().getProgramme() != null
                && p.getProgrammeDegree().getProgramme().getDepartment() != null
                ? p.getProgrammeDegree().getProgramme().getDepartment().getName()
                : null;
        Integer yearOfStudy = (visible && p instanceof StudentProfile student) ? student.getYearOfStudy() : null;
        Integer graduationYear = (visible && p instanceof AlumniProfile alumni) ? alumni.getGraduationYear() : null;
        return new AcademicSummary(department, yearOfStudy, graduationYear, p.getProfilePhotoUrl());
    }

    public Skill resolveOrCreateSkill(String name) {
        String clean = name == null ? "" : name.strip();
        return skills.findByName(clean)
                .orElseGet(() -> skills.saveAndFlush(new Skill(clean)));
    }

    @Transactional(readOnly = true)
    public Optional<Skill> findSkillByName(String name) {
        String clean = name == null ? "" : name.strip();
        return skills.findByName(clean);
    }

    @Transactional(readOnly = true)
    public Optional<SkillReference> findSkillReferenceByName(String name) {
        return findSkillByName(name).map(skill -> new SkillReference(skill.getId(), skill.getName()));
    }

    public Map<String, SkillReference> resolveOrCreateSkillReferences(Collection<String> names) {
        var result = new LinkedHashMap<String, SkillReference>();
        for (String name : names) {
            Skill skill = resolveOrCreateSkill(name);
            result.put(name, new SkillReference(skill.getId(), skill.getName()));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public Map<Long, String> skillNames(Collection<Long> ids) {
        var result = new LinkedHashMap<Long, String>();
        skills.findAllById(ids).forEach(skill -> result.put(skill.getId(), skill.getName()));
        return result;
    }
}
