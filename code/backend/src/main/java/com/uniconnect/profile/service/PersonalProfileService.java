package com.uniconnect.profile.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.mapper.ProfileMapper;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.repository.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class PersonalProfileService {
    private final ProfileAccountService accounts;
    private final PersonalProfileRepository profiles;
    private final ProgrammeDegreeRepository degrees;
    private final SkillRepository skills;
    private final InterestRepository interests;
    private final ProfileValidation validation;
    private final ProfileMapper mapper;
    private final Clock clock;
    public PersonalProfileService(ProfileAccountService accounts, PersonalProfileRepository profiles,
            ProgrammeDegreeRepository degrees, SkillRepository skills, InterestRepository interests,
            ProfileValidation validation, ProfileMapper mapper, Clock clock) {
        this.accounts = accounts; this.profiles = profiles; this.degrees = degrees; this.skills = skills;
        this.interests = interests; this.validation = validation; this.mapper = mapper; this.clock = clock;
    }
    public ProfileResponse mine(SessionPrincipal actor) {
        var user = accounts.lockActiveAccount(actor);
        return mapper.profile(profiles.findByUserUserId(user.getUserId()).orElseThrow(() -> new ResourceNotFoundException("Personal profile", user.getUserId())));
    }
    public ProfileResponse saveStudent(SessionPrincipal actor, StudentProfileRequest request) {
        User user = accountWithRole(actor, PlatformRole.STUDENT);
        validation.validate(request);
        var existing = profiles.findByUserUserId(user.getUserId());
        if (existing.isPresent() && !(existing.get() instanceof StudentProfile)) throw wrongType();
        var degree = selectedDegree(request.programmeDegreeId(), existing.orElse(null));
        if (request.yearOfStudy() < degree.getMinimumYear() || request.yearOfStudy() > degree.getMaximumYear())
            throw new BadRequestException("INVALID_STUDY_YEAR", "Study year is outside the selected degree's permitted range.");
        int year = Year.now(clock).getValue();
        if (request.expectedGraduationYear() != null && request.expectedGraduationYear() < year)
            throw new BadRequestException("INVALID_GRADUATION_YEAR", "Expected graduation year cannot be in the past.");
        LocalDateTime now = now();
        StudentProfile profile = existing.map(p -> (StudentProfile) p).orElseGet(() -> new StudentProfile(user, now));
        updateCommon(profile, user, degree, request.fullName(), request.bio(), request.profilePhotoUrl(), request.skills(), request.interests(), now);
        profile.updateAcademicInfo(validation.code(request.studentNumber()), request.yearOfStudy(), request.expectedGraduationYear());
        profile.setAvailability(request.projectAvailability(), request.mentorshipAvailability(), now);
        return mapper.profile(profiles.saveAndFlush(profile));
    }
    public ProfileResponse saveAlumni(SessionPrincipal actor, AlumniProfileRequest request) {
        User user = accountWithRole(actor, PlatformRole.ALUMNI);
        validation.validate(request);
        if (request.graduationYear() > Year.now(clock).getValue())
            throw new BadRequestException("INVALID_GRADUATION_YEAR", "Graduation year cannot be in the future.");
        var existing = profiles.findByUserUserId(user.getUserId());
        if (existing.isPresent() && !(existing.get() instanceof AlumniProfile)) throw wrongType();
        var degree = selectedDegree(request.programmeDegreeId(), existing.orElse(null));
        LocalDateTime now = now();
        AlumniProfile profile = existing.map(p -> (AlumniProfile) p).orElseGet(() -> new AlumniProfile(user, now));
        updateCommon(profile, user, degree, request.fullName(), request.bio(), request.profilePhotoUrl(), request.skills(), request.interests(), now);
        profile.updateCareerInfo(request.graduationYear(), validation.optional(request.currentCompany()), validation.optional(request.currentPosition()),
                validation.optional(request.industry()), validation.optional(request.careerBackground()), validation.url(request.linkedinUrl(), true));
        return mapper.profile(profiles.saveAndFlush(profile));
    }
    public ProfileResponse availability(SessionPrincipal actor, AvailabilityRequest request) {
        User user = accountWithRole(actor, PlatformRole.STUDENT);
        validation.validate(request);
        var profile = profiles.findByUserUserId(user.getUserId()).orElseThrow(() -> new ResourceNotFoundException("Personal profile", user.getUserId()));
        if (!(profile instanceof StudentProfile student)) throw wrongType();
        student.setAvailability(request.projectAvailability(), request.mentorshipAvailability(), now());
        profiles.flush();
        return mapper.profile(student);
    }
    private User accountWithRole(SessionPrincipal actor, PlatformRole role) {
        User user = accounts.lockActiveAccount(actor);
        if (user.getPlatformRole() != role) throw new ForbiddenException("Profile type must match the account's platform role.");
        return user;
    }
    private ProgrammeDegree selectedDegree(Long id, PersonalProfile existing) {
        var degree = degrees.lockById(id).orElseThrow(() -> new ResourceNotFoundException("Programme degree", id));
        if (!degree.isActive() && (existing == null || !existing.getProgrammeDegree().getId().equals(id)))
            throw new BadRequestException("INACTIVE_ACADEMIC_OPTION", "Select an active degree option.");
        return degree;
    }
    private void updateCommon(PersonalProfile profile, User user, ProgrammeDegree degree, String name,
            String bio, String photo, List<String> skillNames, List<String> interestNames, LocalDateTime now) {
        // Resolve vocabulary in sorted order; unique constraints handle concurrent first use.
        Set<Skill> selectedSkills = new HashSet<>();
        for (String skill : validation.names(skillNames)) selectedSkills.add(skills.findByName(skill).orElseGet(() -> skills.saveAndFlush(new Skill(skill))));
        Set<Interest> selectedInterests = new HashSet<>();
        for (String interest : validation.names(interestNames)) selectedInterests.add(interests.findByName(interest).orElseGet(() -> interests.saveAndFlush(new Interest(interest))));
        profile.updateCommon(degree, validation.optional(bio), validation.url(photo, false), selectedSkills, selectedInterests, now);
        user.updateFullName(validation.required(name), now);
    }
    private ConflictException wrongType() { return new ConflictException("PROFILE_TYPE_CONFLICT", "Existing profile type does not match the account."); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
