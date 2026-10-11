package com.uniconnect.profile.service;

import com.uniconnect.profile.domain.AlumniProfile;
import com.uniconnect.profile.domain.PersonalProfile;
import com.uniconnect.profile.domain.StudentProfile;
import com.uniconnect.profile.repository.PersonalProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@Transactional(propagation = Propagation.MANDATORY, readOnly = true)
public class ProfileQueryService {

    public record AcademicSummary(
            String departmentName,
            Integer yearOfStudy,
            Integer graduationYear,
            String profilePhotoUrl
    ) {}

    private final PersonalProfileRepository profiles;

    public ProfileQueryService(PersonalProfileRepository profiles) {
        this.profiles = profiles;
    }

    public Optional<PersonalProfile> findByUserId(long userId) {
        return profiles.findByUserUserId(userId);
    }

    public Optional<Integer> findStudentYearOfStudy(long userId) {
        return profiles.findByUserUserId(userId)
                .filter(StudentProfile.class::isInstance)
                .map(p -> ((StudentProfile) p).getYearOfStudy());
    }

    public Optional<AcademicSummary> findAcademicSummary(long userId) {
        return profiles.findByUserUserId(userId).map(p -> {
            String department = p.getProgrammeDegree() != null
                    && p.getProgrammeDegree().getProgramme() != null
                    && p.getProgrammeDegree().getProgramme().getDepartment() != null
                    ? p.getProgrammeDegree().getProgramme().getDepartment().getName()
                    : null;
            Integer yearOfStudy = (p instanceof StudentProfile student) ? student.getYearOfStudy() : null;
            Integer graduationYear = (p instanceof AlumniProfile alumni) ? alumni.getGraduationYear() : null;
            return new AcademicSummary(department, yearOfStudy, graduationYear, p.getProfilePhotoUrl());
        });
    }
}
