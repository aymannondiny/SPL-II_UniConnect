package com.uniconnect.mentorship.service;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.dto.ConnectionSummary;
import com.uniconnect.connection.service.ConnectionQueryService;
import com.uniconnect.mentorship.domain.MentorExpertise;
import com.uniconnect.mentorship.domain.MentorProfile;
import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.mentorship.dto.*;
import com.uniconnect.mentorship.repository.MentorProfileRepository;
import com.uniconnect.mentorship.repository.MentorSearchRepository;
import com.uniconnect.profile.domain.Skill;
import com.uniconnect.profile.service.ProfileQueryService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.exception.ForbiddenException;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.validation.Validator;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Map;

@Service
@Transactional
public class PeerMentorService {

    private final MentorProfileRepository mentorProfiles;
    private final MentorSearchRepository mentorSearch;
    private final ProfileAccountService accounts;
    private final ProfileQueryService profileQuery;
    private final ConnectionQueryService connectionQuery;
    private final Validator validator;
    private final Clock clock;

    public PeerMentorService(
            MentorProfileRepository mentorProfiles,
            MentorSearchRepository mentorSearch,
            ProfileAccountService accounts,
            ProfileQueryService profileQuery,
            ConnectionQueryService connectionQuery,
            Validator validator,
            Clock clock
    ) {
        this.mentorProfiles = mentorProfiles;
        this.mentorSearch = mentorSearch;
        this.accounts = accounts;
        this.profileQuery = profileQuery;
        this.connectionQuery = connectionQuery;
        this.validator = validator;
        this.clock = clock;
    }

    public MentorProfileResponse registerMentor(SessionPrincipal actor, MentorRegistrationRequest request) {
        if (request == null || request.expertise() == null
                || request.expertise().stream().anyMatch(java.util.Objects::isNull)
                || !validator.validate(request).isEmpty()) {
            throw new BadRequestException("INVALID_MENTOR_REGISTRATION", "Invalid mentor registration data.");
        }

        User user = accounts.lockActiveAccount(actor);
        if (!user.canPerformProtectedAction()) {
            throw new ForbiddenException("Account cannot perform protected actions.");
        }

        if (user.getPlatformRole() != PlatformRole.STUDENT && user.getPlatformRole() != PlatformRole.ALUMNI) {
            throw new ForbiddenException("Only students and alumni can register as mentors.");
        }

        if (user.getPlatformRole() == PlatformRole.STUDENT) {
            Integer yearOfStudy = profileQuery.findStudentYearOfStudy(user.getUserId())
                    .orElseThrow(() -> new BadRequestException("PROFILE_REQUIRED", "Complete your student profile before registering as a mentor."));
            if (yearOfStudy < 2) {
                throw new ForbiddenException("Peer mentors must be in study year 2 or higher.");
            }
        } else {
            if (profileQuery.findByUserId(user.getUserId()).isEmpty()) {
                throw new BadRequestException("PROFILE_REQUIRED", "Complete your alumni profile before registering as a mentor.");
            }
        }

        if (mentorProfiles.existsByUserUserId(user.getUserId())) {
            throw new ConflictException("MENTOR_ALREADY_REGISTERED", "User is already registered as a mentor.");
        }

        LocalDateTime now = now();
        MentorProfile profile = new MentorProfile(user, request.mentoringBio().strip(), now);
        for (var exp : request.expertise()) {
            Skill skill = profileQuery.resolveOrCreateSkill(exp.topic().strip());
            profile.addExpertise(skill, exp.description() != null ? exp.description().strip() : null);
        }

        profile = mentorProfiles.saveAndFlush(profile);
        return toProfileResponse(profile, user.getUserId(), true);
    }

    @Transactional(readOnly = true)
    public MentorProfileResponse myProfile(SessionPrincipal actor) {
        User user = accounts.activeAccount(actor);
        MentorProfile profile = mentorProfiles.findByUserUserId(user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Mentor profile", user.getUserId()));
        return toProfileResponse(profile, user.getUserId(), true);
    }

    public MentorProfileResponse updateStatus(SessionPrincipal actor, MentorStatusUpdateRequest request) {
        if (request == null || !validator.validate(request).isEmpty()) {
            throw new BadRequestException("INVALID_STATUS_UPDATE", "Invalid status update request.");
        }
        User user = accounts.lockActiveAccount(actor);
        MentorProfile profile = mentorProfiles.findByUserUserId(user.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Mentor profile", user.getUserId()));

        profile.setStatus(request.status(), now());
        mentorProfiles.flush();
        return toProfileResponse(profile, user.getUserId(), true);
    }

    @Transactional(readOnly = true)
    public MentorProfileResponse getMentorProfile(SessionPrincipal actor, Long mentorProfileId) {
        accounts.activeAccount(actor);
        MentorProfile profile = mentorProfiles.findById(mentorProfileId)
                .filter(p -> p.getUser().canPerformProtectedAction())
                .orElseThrow(() -> new ResourceNotFoundException("Mentor profile", mentorProfileId));

        boolean isOwner = profile.getUser().getUserId().equals(actor.userId());
        if (!isOwner && profile.getStatus() == MentorStatus.UNAVAILABLE) {
            throw new ResourceNotFoundException("Mentor profile", mentorProfileId);
        }

        boolean areConnected = isOwner || connectionQuery.areAccepted(actor.userId(), profile.getUser().getUserId());
        return toProfileResponse(profile, actor.userId(), areConnected);
    }

    @Transactional(readOnly = true)
    public PageResponse<MentorSummaryResponse> searchMentors(
            SessionPrincipal actor,
            String topic,
            Long departmentId,
            Integer yearOfStudy,
            int page,
            int size
    ) {
        accounts.activeAccount(actor);
        PageValidation.check(page, size);

        MentorSearchCriteria criteria = MentorSearchCriteria.of(topic, departmentId, yearOfStudy, page, size);
        PageResponse<MentorProfile> resultPage = mentorSearch.search(criteria);

        Map<Long, ConnectionSummary> relations = connectionQuery.relationships(actor.userId());
        var connected = relations.keySet().stream()
                .filter(userId -> isConnected(relations, userId))
                .collect(java.util.stream.Collectors.toSet());
        var academics = profileQuery.findAcademicSummaries(
                resultPage.items().stream().map(p -> p.getUser().getUserId()).toList(),
                actor.userId(), connected);
        List<MentorSummaryResponse> items = resultPage.items().stream()
                .map(p -> toSummaryResponse(p, academics.get(p.getUser().getUserId())))
                .toList();

        return new PageResponse<>(items, page, size, resultPage.totalElements());
    }

    @Transactional(readOnly = true)
    public PageResponse<MentorSummaryResponse> searchMentors(
            SessionPrincipal actor,
            String topic,
            int page,
            int size
    ) {
        return searchMentors(actor, topic, null, null, page, size);
    }

    private boolean isConnected(Map<Long, ConnectionSummary> relations, Long targetUserId) {
        if (relations == null || targetUserId == null) return false;
        ConnectionSummary summary = relations.get(targetUserId);
        return summary != null && summary.status() == ConnectionStatus.ACCEPTED;
    }

    private MentorProfileResponse toProfileResponse(MentorProfile profile, Long viewerId, boolean areConnected) {
        var academic = profileQuery.findAcademicSummary(profile.getUser().getUserId(), viewerId, areConnected).orElse(null);
        String departmentName = academic != null ? academic.departmentName() : null;
        Integer yearOfStudy = academic != null ? academic.yearOfStudy() : null;
        Integer graduationYear = academic != null ? academic.graduationYear() : null;
        String photoUrl = academic != null ? academic.profilePhotoUrl() : null;

        List<ExpertiseResponse> expertiseResponses = profile.getExpertise().stream()
                .map(e -> new ExpertiseResponse(e.getId(), e.getTopic(), e.getDescription()))
                .toList();

        return new MentorProfileResponse(
                profile.getId(),
                profile.getUser().getUserId(),
                profile.getUser().getFullName(),
                profile.getUser().getPlatformRole(),
                departmentName,
                yearOfStudy,
                graduationYear,
                photoUrl,
                profile.getMentoringBio(),
                profile.getStatus(),
                expertiseResponses,
                profile.getRegisteredAt(),
                profile.getUpdatedAt()
        );
    }

    private MentorSummaryResponse toSummaryResponse(
            MentorProfile profile, ProfileQueryService.AcademicSummary academic) {
        String departmentName = academic != null ? academic.departmentName() : null;
        Integer yearOfStudy = academic != null ? academic.yearOfStudy() : null;
        Integer graduationYear = academic != null ? academic.graduationYear() : null;
        String photoUrl = academic != null ? academic.profilePhotoUrl() : null;

        List<String> topics = profile.getExpertise().stream()
                .map(MentorExpertise::getTopic)
                .toList();

        return new MentorSummaryResponse(
                profile.getId(),
                profile.getUser().getUserId(),
                profile.getUser().getFullName(),
                profile.getUser().getPlatformRole(),
                departmentName,
                yearOfStudy,
                graduationYear,
                photoUrl,
                profile.getStatus(),
                topics
        );
    }

    private LocalDateTime now() {
        return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
    }
}
