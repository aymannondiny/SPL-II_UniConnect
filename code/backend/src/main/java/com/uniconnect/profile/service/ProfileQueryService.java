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

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ProfileQueryService {

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
        return profiles.findByUserUserId(userId).map(p -> {
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
        });
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
}
