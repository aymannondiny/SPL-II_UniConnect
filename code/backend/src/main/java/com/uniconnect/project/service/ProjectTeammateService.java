package com.uniconnect.project.service;

import com.uniconnect.authentication.service.InvalidSessionException;
import com.uniconnect.authentication.service.ProjectAccountService;
import com.uniconnect.notification.service.ProjectNotificationService;
import com.uniconnect.profile.service.ProfileQueryService;
import com.uniconnect.profile.service.ProjectProfileService;
import com.uniconnect.project.domain.*;
import com.uniconnect.project.dto.*;
import com.uniconnect.project.repository.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.persistence.criteria.JoinType;
import java.time.*;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ProjectTeammateService {
    private static final ZoneId PROJECT_ZONE = ZoneId.of("Asia/Dhaka");
    private final ProjectRepository projects;
    private final ProjectMembershipRepository memberships;
    private final ProjectApplicationRepository applications;
    private final ProjectAuditRepository audits;
    private final ProjectAccountService accounts;
    private final ProfileQueryService profileQueries;
    private final ProjectProfileService profiles;
    private final ProjectNotificationService notifications;
    private final ProjectValidation validation;
    private final ProjectRecommendationScorer recommendationScorer;
    private final Clock clock;

    public ProjectTeammateService(ProjectRepository projects, ProjectMembershipRepository memberships,
            ProjectApplicationRepository applications, ProjectAuditRepository audits,
            ProjectAccountService accounts, ProfileQueryService profileQueries, ProjectProfileService profiles,
            ProjectNotificationService notifications, ProjectValidation validation,
            ProjectRecommendationScorer recommendationScorer, Clock clock) {
        this.projects = projects; this.memberships = memberships; this.applications = applications;
        this.audits = audits; this.accounts = accounts; this.profileQueries = profileQueries;
        this.profiles = profiles; this.notifications = notifications; this.validation = validation;
        this.recommendationScorer = recommendationScorer; this.clock = clock;
    }

    public ProjectResponse create(SessionPrincipal principal, ProjectRequest request) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        var input = validation.project(request, today());
        var skills = resolveSkills(input.skills());
        LocalDateTime now = now();
        Project project = projects.saveAndFlush(new Project(actor.id(), input.title(), input.description(), input.limit(),
                input.duration(), input.courseName(), input.deadline(), skills, now));
        memberships.saveAndFlush(new ProjectMembership(project, actor.id(), ProjectMemberRole.CREATOR, now));
        audit(project.getProjectId(), actor.id(), null, ProjectAuditEvent.CREATED, now);
        return response(project, 1, actor, actor, null, true);
    }

    public ProjectResponse update(SessionPrincipal principal, long projectId, ProjectRequest request) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        var input = validation.project(request, today());
        Project project = lockOwned(projectId, actor.id());
        long count = memberships.countByProjectProjectId(projectId);
        if (input.limit() < count) throw state("Capacity cannot be below current membership count.");
        project.update(input.title(), input.description(), input.limit(), input.duration(), input.courseName(),
                input.deadline(), resolveSkills(input.skills()), now());
        projects.flush(); audit(projectId, actor.id(), null, ProjectAuditEvent.UPDATED, now());
        return response(project, count, actor, actor, null, true);
    }

    public ProjectResponse close(SessionPrincipal principal, long projectId) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        Project project = lockOwned(projectId, actor.id());
        long count = memberships.countByProjectProjectId(projectId);
        if (project.getStatus() == ProjectStatus.CLOSED) return response(project, count, actor, actor, null, true);
        project.close(now()); audit(projectId, actor.id(), null, ProjectAuditEvent.CLOSED, now());
        return response(project, count, actor, actor, null, true);
    }

    public ProjectResponse reopen(SessionPrincipal principal, long projectId) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        Project project = lockOwned(projectId, actor.id());
        long count = memberships.countByProjectProjectId(projectId);
        if (project.getStatus() == ProjectStatus.OPEN) {
            if (count >= project.getTeamSizeLimit() || project.expired(today())) throw state("Reopening requires a vacancy and a valid deadline.");
            return response(project, count, actor, actor, null, true);
        }
        if (count >= project.getTeamSizeLimit() || project.expired(today()))
            throw state("Reopening requires a vacancy and a valid deadline.");
        project.reopen(now()); audit(projectId, actor.id(), null, ProjectAuditEvent.REOPENED, now());
        return response(project, count, actor, actor, null, true);
    }

    public void delete(SessionPrincipal principal, long projectId) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        Project project = lockOwned(projectId, actor.id());
        deleteLocked(project, actor.id(), ProjectAuditEvent.DELETED, now());
    }

    public ProjectApplicationResponse apply(SessionPrincipal principal, long projectId,
            ProjectApplicationRequest request) {
        Project initial = requireVisible(projectId);
        var lockedAccounts = accounts.lock(principal, List.of(initial.getCreatorUserId()));
        var actor = requireEligible(lockedAccounts.get(principal.userId()));
        var creator = lockedAccounts.get(initial.getCreatorUserId());
        if (creator == null || !creator.eligibleStudent()) throw state("The project creator is currently unavailable.");
        Project project = projects.lockById(projectId).orElseThrow(() -> missing(projectId));
        if (project.getStatus() == ProjectStatus.DELETED) throw missing(projectId);
        if (actor.id() == project.getCreatorUserId()) throw state("The creator cannot apply to their own project.");
        if (project.getStatus() != ProjectStatus.OPEN || project.expired(today()))
            throw state("This project is not accepting applications.");
        long count = memberships.countByProjectProjectId(projectId);
        if (count >= project.getTeamSizeLimit()) throw state("This project is full.");
        if (memberships.existsByProjectProjectIdAndMemberUserId(projectId, actor.id()))
            throw state("Existing project members cannot apply.");
        if (applications.existsByProjectProjectIdAndApplicantUserId(projectId, actor.id())) throw duplicateApplication();
        LocalDateTime now = now();
        try {
            ProjectApplication application = applications.saveAndFlush(
                    new ProjectApplication(project, actor.id(), validation.message(request), now));
            audit(projectId, actor.id(), application.getApplicationId(), ProjectAuditEvent.APPLICATION_SUBMITTED, now);
            return applicationResponse(application, actor.displayName());
        } catch (DataIntegrityViolationException duplicate) {
            throw duplicateApplication();
        }
    }

    public ProjectApplicationResponse accept(SessionPrincipal principal, long applicationId) {
        return review(principal, applicationId, true);
    }

    public ProjectApplicationResponse reject(SessionPrincipal principal, long applicationId) {
        return review(principal, applicationId, false);
    }

    private ProjectApplicationResponse review(SessionPrincipal principal, long applicationId, boolean accept) {
        ProjectApplication initial = applications.findById(applicationId)
                .orElseThrow(() -> new ResourceNotFoundException("Project application", applicationId));
        long creatorId = initial.getProject().getCreatorUserId();
        long applicantId = initial.getApplicantUserId();
        var lockedAccounts = accounts.lock(principal, List.of(creatorId, applicantId));
        var actor = requireEligible(lockedAccounts.get(principal.userId()));
        Project project = lockOwned(initial.getProject().getProjectId(), actor.id());
        ProjectApplication application = applications.lockById(applicationId)
                .orElseThrow(() -> new ResourceNotFoundException("Project application", applicationId));
        ProjectApplicationStatus desired = accept ? ProjectApplicationStatus.ACCEPTED : ProjectApplicationStatus.REJECTED;
        if (application.getStatus() == desired)
            return applicationResponse(application, lockedAccounts.get(applicantId).displayName());
        if (application.getStatus() != ProjectApplicationStatus.PENDING)
            throw state("Only a pending application may be reviewed.");
        if (accept && !lockedAccounts.get(applicantId).eligibleStudent())
            throw state("Only an ACTIVE, non-anonymized STUDENT may become a project member.");
        LocalDateTime now = now();
        if (accept) {
            long count = memberships.countByProjectProjectId(project.getProjectId());
            if (count >= project.getTeamSizeLimit()) throw state("This project is full.");
            if (!memberships.existsByProjectProjectIdAndMemberUserId(project.getProjectId(), applicantId))
                memberships.saveAndFlush(new ProjectMembership(project, applicantId, ProjectMemberRole.TEAMMATE, now));
            application.accept(now);
        } else application.reject(now);
        applications.flush();
        audit(project.getProjectId(), actor.id(), applicationId,
                accept ? ProjectAuditEvent.APPLICATION_ACCEPTED : ProjectAuditEvent.APPLICATION_REJECTED, now);
        notifications.applicationReviewed(applicantId, project.getProjectId(), applicationId, accept, now);
        return applicationResponse(application, lockedAccounts.get(applicantId).displayName());
    }

    public PageResponse<ProjectResponse> browse(SessionPrincipal principal, ProjectStatus status,
            ProjectAvailability availability, Long departmentId, String skill, ProjectSort sort, int page, int size) {
        var viewer = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        PageValidation.check(page, size);
        String cleanSkill = validation.skill(skill);
        Long skillId = null;
        if (cleanSkill != null) {
            var found = profileQueries.findSkillReferenceByName(cleanSkill);
            if (found.isEmpty()) return empty(page, size);
            skillId = found.get().id();
        }
        Set<Long> creators = departmentId == null ? null : profiles.userIdsInDepartment(departmentId);
        if (creators != null && creators.isEmpty()) return empty(page, size);
        var spec = specification(status, availability, creators, skillId);
        Sort ordering = (sort == null ? ProjectSort.CREATED_DESC : sort) == ProjectSort.DEADLINE_ASC
                ? Sort.by(Sort.Order.asc("applicationDeadline"), Sort.Order.asc("projectId"))
                : Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("projectId"));
        Page<Project> result = projects.findAll(spec, PageRequest.of(page, size, ordering));
        return responsePage(result, viewer);
    }

    public ProjectResponse detail(SessionPrincipal principal, long projectId) {
        var viewer = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        Project project = requireVisible(projectId);
        long count = memberships.countByProjectProjectId(projectId);
        var current = applications.findByProjectProjectIdAndApplicantUserId(projectId, viewer.id())
                .map(ProjectApplication::getStatus).orElse(null);
        boolean member = memberships.existsByProjectProjectIdAndMemberUserId(projectId, viewer.id());
        var creator = accounts.summaries(List.of(project.getCreatorUserId())).get(project.getCreatorUserId());
        return response(project, count, creator, viewer, current, member);
    }

    /**
     * Resolves the ordinary non-deleted project detail that Content Reporting may retain.
     * Reporting is available to every ACTIVE account and is independent of project
     * application, membership, recommendation, or management eligibility.
     */
    public ProjectReportTarget reportable(SessionPrincipal principal, long projectId) {
        var viewer = accounts.current(principal);
        if (viewer == null || !viewer.active()) throw new InvalidSessionException();
        Project project = projects.lockById(projectId)
                .filter(candidate -> candidate.getStatus() != ProjectStatus.DELETED)
                .orElseThrow(() -> missing(projectId));
        long memberCount = memberships.countByProjectProjectId(projectId);
        var creator = accounts.summaries(List.of(project.getCreatorUserId())).get(project.getCreatorUserId());
        var skillNames = profileQueries.skillNames(project.getSkills().stream()
                .map(ProjectSkill::getSkillId).toList());
        var skillDtos = project.getSkills().stream()
                .map(skill -> new ProjectSkillResponse(skill.getSkillId(),
                        skillNames.getOrDefault(skill.getSkillId(), "Unknown skill"), skill.isRequired()))
                .sorted(Comparator.comparing(ProjectSkillResponse::name).thenComparingLong(ProjectSkillResponse::id))
                .toList();
        boolean redacted = project.getCreatorRedactedAt() != null;
        var snapshot = new ProjectReportSnapshot(project.getProjectId(),
                redacted ? null : project.getCreatorUserId(),
                redacted || creator == null ? "Former User" : creator.displayName(),
                project.getTitle(), project.getDescription(), project.getTeamSizeLimit(), project.getDuration(),
                project.getCourseName(), project.getApplicationDeadline(), project.getStatus(),
                project.availability(today(), memberCount), skillDtos, project.getCreatedAt(), project.getUpdatedAt(),
                project.getClosedAt());
        return new ProjectReportTarget(project.getTitle(), project.getCreatorUserId(), snapshot);
    }

    public PageResponse<ProjectResponse> mine(SessionPrincipal principal, int page, int size) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        PageValidation.check(page, size);
        Specification<Project> spec = (root, query, cb) -> cb.and(
                cb.equal(root.get("creatorUserId"), actor.id()), cb.notEqual(root.get("status"), ProjectStatus.DELETED));
        return responsePage(projects.findAll(spec, PageRequest.of(page, size,
                Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("projectId")))), actor);
    }

    public PageResponse<AppliedProjectResponse> applied(SessionPrincipal principal, int page, int size) {
        var viewer = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        PageValidation.check(page, size);
        Page<ProjectApplication> result = applications.findByApplicantUserIdOrderByAppliedAtDescApplicationIdDesc(
                viewer.id(), PageRequest.of(page, size));
        var creatorIds = result.getContent().stream().map(application -> application.getProject().getCreatorUserId())
                .distinct().toList();
        var creators = accounts.summaries(creatorIds);
        var items = result.getContent().stream().map(application -> {
            Project project = application.getProject();
            ProjectResponse projectResponse = null;
            if (project.getStatus() != ProjectStatus.DELETED) {
                long count = memberships.countByProjectProjectId(project.getProjectId());
                boolean member = memberships.existsByProjectProjectIdAndMemberUserId(project.getProjectId(), viewer.id());
                projectResponse = response(project, count, creators.get(project.getCreatorUserId()), viewer,
                        application.getStatus(), member);
            }
            return new AppliedProjectResponse(projectResponse,
                    applicationResponse(application, viewer.displayName()));
        }).toList();
        return new PageResponse<>(items, page, size, result.getTotalElements());
    }

    @Transactional(readOnly = true)
    public List<ProjectRecommendationResponse> recommendations(SessionPrincipal principal, long projectId) {
        var actor = requireEligible(accounts.current(principal));
        Project project = requireOwned(projectId, actor.id());
        long memberCount = memberships.countByProjectProjectId(projectId);
        if (project.getStatus() != ProjectStatus.OPEN || project.expired(today())
                || memberCount >= project.getTeamSizeLimit()) return List.of();

        Set<Long> excluded = new LinkedHashSet<>();
        excluded.add(project.getCreatorUserId());
        memberships.findByProjectProjectIdOrderByMembershipId(projectId)
                .forEach(membership -> excluded.add(membership.getMemberUserId()));
        applications.findByProjectProjectIdOrderByApplicationId(projectId)
                .forEach(application -> excluded.add(application.getApplicantUserId()));

        Map<Long, String> allSkillNames = profileQueries.skillNames(project.getSkills().stream()
                .map(ProjectSkill::getSkillId).toList());
        Set<String> required = project.getSkills().stream().filter(ProjectSkill::isRequired)
                .map(skill -> allSkillNames.get(skill.getSkillId())).filter(Objects::nonNull)
                .map(value -> value.toLowerCase(Locale.ROOT)).collect(Collectors.toCollection(LinkedHashSet::new));
        Set<String> optional = project.getSkills().stream().filter(skill -> !skill.isRequired())
                .map(skill -> allSkillNames.get(skill.getSkillId())).filter(Objects::nonNull)
                .map(value -> value.toLowerCase(Locale.ROOT)).collect(Collectors.toCollection(LinkedHashSet::new));
        Set<String> relevantSkills = new LinkedHashSet<>(required);
        relevantSkills.addAll(optional);
        if (required.isEmpty()) return List.of();
        List<String> creatorInterests = profiles.interests(actor.id());

        record ScoredCandidate(ProjectRecommendationResponse response, java.math.BigDecimal rawTotal) {}
        return profiles.availableProjectCandidates(actor.id(), excluded, relevantSkills).stream()
                .map(candidate -> recommendationScorer.score(required, optional, candidate.skills(), creatorInterests,
                        candidate.interests(), candidate.directlyConnected()).map(score -> new ScoredCandidate(
                                new ProjectRecommendationResponse(candidate.userId(), candidate.displayName(),
                                        candidate.profilePhotoUrl(), candidate.departmentName(),
                                        score.matchedRequiredSkills(), score.matchedOptionalSkills(), score.score(),
                                        score.skillPoints(), score.interestPoints(), score.connectionPoints(),
                                        score.matchedInterests(), score.directlyConnected()), score.rawTotal())))
                .flatMap(Optional::stream)
                .sorted(Comparator.comparing(ScoredCandidate::rawTotal).reversed()
                        .thenComparing(candidate -> recommendationScorer.normalizeName(
                                candidate.response().displayName()))
                        .thenComparingLong(candidate -> candidate.response().userId()))
                .limit(20).map(ScoredCandidate::response).toList();
    }

    public PageResponse<ProjectApplicationResponse> applications(SessionPrincipal principal, long projectId,
            int page, int size) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        PageValidation.check(page, size); lockOwned(projectId, actor.id());
        Page<ProjectApplication> result = applications.findByProjectProjectId(projectId,
                PageRequest.of(page, size, Sort.by(Sort.Order.desc("applicationId"))));
        var names = accounts.displayNames(result.getContent().stream().map(ProjectApplication::getApplicantUserId).toList());
        var items = result.getContent().stream().map(a -> applicationResponse(a,
                names.getOrDefault(a.getApplicantUserId(), "Former User"))).toList();
        return new PageResponse<>(items, page, size, result.getTotalElements());
    }

    public List<ProjectMembershipResponse> members(SessionPrincipal principal, long projectId) {
        requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        requireVisible(projectId);
        var rows = memberships.findByProjectProjectIdOrderByMembershipId(projectId);
        var names = accounts.displayNames(rows.stream().map(ProjectMembership::getMemberUserId).toList());
        return rows.stream().map(m -> new ProjectMembershipResponse(m.getMembershipId(), m.getMemberUserId(),
                names.getOrDefault(m.getMemberUserId(), "Former User"), m.getRole(), m.getJoinedAt())).toList();
    }

    public PageResponse<ProjectAuditResponse> audit(SessionPrincipal principal, long projectId, int page, int size) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        PageValidation.check(page, size); lockOwned(projectId, actor.id());
        var result = audits.findByProjectId(projectId,
                PageRequest.of(page, size, Sort.by(Sort.Order.desc("auditId"))));
        return new PageResponse<>(result.map(a -> new ProjectAuditResponse(a.getAuditId(), a.getActorUserId(),
                a.getApplicationId(), a.getEventType(), a.getOccurredAt())).getContent(), page, size,
                result.getTotalElements());
    }

    private void deleteLocked(Project project, Long actorId, ProjectAuditEvent event, LocalDateTime now) {
        if (project.getStatus() == ProjectStatus.DELETED) return;
        project.delete(now);
        var pending = applications.lockByProjectAndStatus(project.getProjectId(), ProjectApplicationStatus.PENDING);
        for (var application : pending) {
            application.cancel(now);
            audit(project.getProjectId(), actorId, application.getApplicationId(),
                    ProjectAuditEvent.APPLICATION_CANCELLED, now);
            notifications.projectDeleted(application.getApplicantUserId(), project.getProjectId(),
                    application.getApplicationId(), now);
        }
        audit(project.getProjectId(), actorId, null, event, now);
        applications.flush(); projects.flush();
    }

    private Specification<Project> specification(ProjectStatus status, ProjectAvailability availability,
            Set<Long> creators, Long skillId) {
        LocalDate today = today();
        return (root, query, cb) -> {
            var predicates = new ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(cb.notEqual(root.get("status"), ProjectStatus.DELETED));
            if (status != null) predicates.add(cb.equal(root.get("status"), status));
            if (status == null && availability == null) {
                predicates.add(cb.equal(root.get("status"), ProjectStatus.OPEN));
                predicates.add(cb.greaterThanOrEqualTo(root.get("applicationDeadline"), today));
            }
            if (creators != null) predicates.add(root.get("creatorUserId").in(creators));
            if (skillId != null) {
                query.distinct(true);
                predicates.add(cb.equal(root.join("skills", JoinType.INNER).get("skillId"), skillId));
            }
            if (availability != null) {
                if (availability == ProjectAvailability.CLOSED) {
                    predicates.add(cb.equal(root.get("status"), ProjectStatus.CLOSED));
                } else if (availability == ProjectAvailability.EXPIRED) {
                    predicates.add(cb.equal(root.get("status"), ProjectStatus.OPEN));
                    predicates.add(cb.lessThan(root.get("applicationDeadline"), today));
                } else {
                    predicates.add(cb.equal(root.get("status"), ProjectStatus.OPEN));
                    predicates.add(cb.greaterThanOrEqualTo(root.get("applicationDeadline"), today));
                    var count = query.subquery(Long.class);
                    var member = count.from(ProjectMembership.class);
                    count.select(cb.count(member));
                    count.where(cb.equal(member.get("project").get("projectId"), root.get("projectId")));
                    var full = cb.greaterThanOrEqualTo(count, root.get("teamSizeLimit"));
                    predicates.add(availability == ProjectAvailability.FULL ? full : cb.not(full));
                }
            }
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
    }

    private Set<ProjectSkill> resolveSkills(List<ProjectSkillRequest> requested) {
        var refs = profileQueries.resolveOrCreateSkillReferences(requested.stream().map(ProjectSkillRequest::name).toList());
        return requested.stream().map(skill -> new ProjectSkill(refs.get(skill.name()).id(), skill.required()))
                .collect(Collectors.toCollection(LinkedHashSet::new));
    }

    private PageResponse<ProjectResponse> responsePage(Page<Project> result,
            ProjectAccountService.Account viewer) {
        var content = result.getContent();
        var ids = content.stream().map(Project::getProjectId).toList();
        var counts = new HashMap<Long, Long>();
        if (!ids.isEmpty()) memberships.counts(ids).forEach(row -> counts.put((Long) row[0], (Long) row[1]));
        var creatorAccounts = accounts.summaries(content.stream().map(Project::getCreatorUserId).toList());
        Set<Long> memberProjects = ids.isEmpty() ? Set.of() : memberships.projectIdsForMember(ids, viewer.id());
        var applicationStatuses = new HashMap<Long, ProjectApplicationStatus>();
        if (!ids.isEmpty()) applications.findByProjectProjectIdInAndApplicantUserId(ids, viewer.id())
                .forEach(application -> applicationStatuses.put(application.getProject().getProjectId(),
                        application.getStatus()));
        var items = content.stream().map(p -> response(p, counts.getOrDefault(p.getProjectId(), 0L),
                creatorAccounts.get(p.getCreatorUserId()), viewer, applicationStatuses.get(p.getProjectId()),
                memberProjects.contains(p.getProjectId()))).toList();
        return new PageResponse<>(items, result.getNumber(), result.getSize(), result.getTotalElements());
    }

    private ProjectResponse response(Project project, long count, ProjectAccountService.Account creator,
            ProjectAccountService.Account viewer, ProjectApplicationStatus currentApplicationStatus,
            boolean viewerMember) {
        var department = profiles.departments(List.of(project.getCreatorUserId())).get(project.getCreatorUserId());
        var skillNames = profileQueries.skillNames(project.getSkills().stream().map(ProjectSkill::getSkillId).toList());
        var skillDtos = project.getSkills().stream().map(skill -> new ProjectSkillResponse(skill.getSkillId(),
                skillNames.getOrDefault(skill.getSkillId(), "Unknown skill"), skill.isRequired())).toList();
        boolean redacted = project.getCreatorRedactedAt() != null;
        long vacancies = Math.max(0, project.getTeamSizeLimit() - count);
        var availability = project.availability(today(), count);
        boolean canApply = viewer != null && viewer.eligibleStudent()
                && creator != null && creator.eligibleStudent()
                && viewer.id() != project.getCreatorUserId()
                && !viewerMember && currentApplicationStatus == null
                && availability == ProjectAvailability.AVAILABLE;
        return new ProjectResponse(project.getProjectId(), redacted ? null : project.getCreatorUserId(),
                redacted ? "Former User" : creator == null ? "Former User" : creator.displayName(),
                redacted || department == null ? null : department.id(),
                redacted || department == null ? null : department.code(),
                redacted || department == null ? null : department.name(), project.getTitle(), project.getDescription(),
                project.getTeamSizeLimit(), project.getDuration(), project.getCourseName(),
                project.getApplicationDeadline(), project.getStatus(), availability, count, vacancies, vacancies == 0,
                canApply, currentApplicationStatus, skillDtos, project.getCreatedAt(),
                project.getUpdatedAt(), project.getClosedAt());
    }

    private ProjectApplicationResponse applicationResponse(ProjectApplication application, String name) {
        return new ProjectApplicationResponse(application.getApplicationId(), application.getProject().getProjectId(),
                application.getApplicantUserId(), name, application.getMessage(), application.getStatus(),
                application.getAppliedAt(), application.getRespondedAt());
    }
    private void audit(long project, Long actor, Long application, ProjectAuditEvent event, LocalDateTime now) {
        audits.save(new ProjectAudit(project, actor, application, event, now));
    }
    private Project requireVisible(long id) {
        return projects.findById(id).filter(p -> p.getStatus() != ProjectStatus.DELETED)
                .orElseThrow(() -> missing(id));
    }
    private Project lockOwned(long id, long creator) {
        Project project = projects.lockById(id).filter(p -> p.getStatus() != ProjectStatus.DELETED)
                .orElseThrow(() -> missing(id));
        if (project.getCreatorUserId() != creator) throw missing(id);
        return project;
    }
    private Project requireOwned(long id, long creator) {
        Project project = requireVisible(id);
        if (project.getCreatorUserId() != creator) throw missing(id);
        return project;
    }
    private ProjectAccountService.Account requireEligible(ProjectAccountService.Account account) {
        if (account == null || !account.eligibleStudent())
            throw new ForbiddenException("Project Teammate Finder requires an ACTIVE, non-anonymized STUDENT account.");
        return account;
    }
    private <T> PageResponse<T> empty(int page, int size) { return new PageResponse<>(List.of(), page, size, 0); }
    private LocalDate today() { return LocalDate.now(clock.withZone(PROJECT_ZONE)); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
    private ResourceNotFoundException missing(long id) { return new ResourceNotFoundException("Project", id); }
    private ConflictException state(String message) { return new ConflictException("INVALID_PROJECT_STATE", message); }
    private ConflictException duplicateApplication() {
        return new ConflictException("DUPLICATE_PROJECT_APPLICATION", "A student may apply only once to a project.");
    }
}
