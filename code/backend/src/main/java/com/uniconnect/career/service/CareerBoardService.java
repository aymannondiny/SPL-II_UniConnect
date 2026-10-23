package com.uniconnect.career.service;

import com.uniconnect.authentication.service.CareerAccountService;
import com.uniconnect.career.domain.ApplicationChannel;
import com.uniconnect.career.domain.CareerSort;
import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.JobPost;
import com.uniconnect.career.domain.JobPostStatus;
import com.uniconnect.career.domain.JobSkill;
import com.uniconnect.career.domain.SavedJob;
import com.uniconnect.career.domain.WorkMode;
import com.uniconnect.career.dto.CareerPostRequest;
import com.uniconnect.career.dto.CareerPostReportSnapshot;
import com.uniconnect.career.dto.CareerPostResponse;
import com.uniconnect.career.dto.SaveJobRequest;
import com.uniconnect.career.dto.SavedJobResponse;
import com.uniconnect.career.dto.UpdateSavedNoteRequest;
import com.uniconnect.career.mapper.CareerMapper;
import com.uniconnect.career.repository.JobPostRepository;
import com.uniconnect.career.repository.SavedJobRepository;
import com.uniconnect.profile.service.ProfileQueryService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.exception.ConflictException;
import com.uniconnect.shared.exception.ForbiddenException;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.persistence.criteria.JoinType;
import java.net.URI;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class CareerBoardService {
    private static final ZoneId CAREER_ZONE = ZoneId.of("Asia/Dhaka");

    private final JobPostRepository posts;
    private final SavedJobRepository savedJobs;
    private final CareerAccountService accounts;
    private final ProfileQueryService profiles;
    private final CareerValidation validation;
    private final CareerMapper mapper;
    private final Clock clock;

    public CareerBoardService(JobPostRepository posts, SavedJobRepository savedJobs,
            CareerAccountService accounts, ProfileQueryService profiles, CareerValidation validation,
            CareerMapper mapper, Clock clock) {
        this.posts = posts;
        this.savedJobs = savedJobs;
        this.accounts = accounts;
        this.profiles = profiles;
        this.validation = validation;
        this.mapper = mapper;
        this.clock = clock;
    }

    public CareerPostResponse create(SessionPrincipal principal, CareerPostRequest request) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.ALUMNI);
        LocalDate today = today();
        var input = validation.post(request, today);
        var skillRefs = profiles.resolveOrCreateSkillReferences(input.skills().stream().map(s -> s.name()).toList());
        var skills = new LinkedHashSet<JobSkill>();
        input.skills().forEach(skill -> skills.add(new JobSkill(skillRefs.get(skill.name()).id(), skill.required())));
        var post = posts.saveAndFlush(new JobPost(actor.userId(), input.title(), input.companyName(),
                input.description(), input.qualifications(), input.location(), input.employmentType(), input.workMode(),
                input.salaryRange(), input.applicationUrl(), input.applicationEmail(), input.applicationDeadline(),
                skills, now()));
        return response(post, actor.displayName(), false, false, today);
    }

    public PageResponse<CareerPostResponse> browse(SessionPrincipal principal, EmploymentType employmentType,
            String location, WorkMode workMode, String skill, CareerSort sort, int page, int size) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        PageValidation.check(page, size);
        LocalDate today = today();
        String cleanLocation = validation.location(location);
        String cleanSkill = validation.skill(skill);
        Long skillId = null;
        if (cleanSkill != null) {
            var reference = profiles.findSkillReferenceByName(cleanSkill);
            if (reference.isEmpty()) return new PageResponse<>(List.of(), page, size, 0);
            skillId = reference.get().id();
        }
        Specification<JobPost> specification = activeSpecification(today, employmentType, cleanLocation, workMode, skillId);
        Sort ordering = (sort == null ? CareerSort.POSTED_AT_DESC : sort) == CareerSort.DEADLINE_ASC
                ? Sort.by(Sort.Order.asc("applicationDeadline"), Sort.Order.asc("jobPostId"))
                : Sort.by(Sort.Order.desc("postedAt"), Sort.Order.desc("jobPostId"));
        Page<JobPost> result = posts.findAll(specification, PageRequest.of(page, size, ordering));
        return page(result, actor.userId(), true);
    }

    public CareerPostResponse detail(SessionPrincipal principal, long id) {
        var actor = accounts.lockActive(principal);
        JobPost post = require(id);
        if (post.getStatus() == JobPostStatus.REMOVED) throw missing(id);
        LocalDate today = today();
        boolean saved = false;
        if (actor.role() == PlatformRole.STUDENT) {
            saved = savedJobs.existsByStudentUserIdAndJobPostJobPostId(actor.userId(), id);
            if (!post.isActive(today) && !saved) throw missing(id);
        } else if (actor.role() == PlatformRole.ALUMNI) {
            if (post.getAuthorUserId() != actor.userId()) throw missing(id);
        } else {
            throw new ForbiddenException("Career Board access is limited to students and alumni authors.");
        }
        return response(post, authorName(post), saved, actor.role() == PlatformRole.STUDENT, today);
    }

    /**
     * Resolves Career's authoritative reportable detail without requiring the
     * caller to be able to save, apply to, edit, or manage the post. Active posts
     * are visible to every ACTIVE account. Closed, expired, or unavailable posts
     * retain access only for their author or a student who previously saved them.
     */
    public CareerPostReportTarget reportable(SessionPrincipal principal, long id) {
        var actor = accounts.lockActive(principal);
        JobPost post = posts.lockById(id).orElseThrow(() -> missing(id));
        if (post.getStatus() == JobPostStatus.REMOVED) throw missing(id);
        LocalDate today = today();
        boolean saved = actor.role() == PlatformRole.STUDENT
                && savedJobs.existsByStudentUserIdAndJobPostJobPostId(actor.userId(), id);
        boolean author = post.getAuthorUserId() == actor.userId();
        if (!post.isActive(today) && !author && !saved) throw missing(id);
        CareerPostResponse visible = response(post, authorName(post), saved,
                actor.role() == PlatformRole.STUDENT, today);
        var snapshot = new CareerPostReportSnapshot(visible.id(), visible.authorUserId(),
                visible.authorDisplayName(), visible.title(), visible.companyName(), visible.description(),
                visible.qualifications(), visible.location(), visible.employmentType(), visible.workMode(),
                visible.salaryRange(), visible.applicationUrl(), visible.applicationEmail(),
                visible.applicationDeadline(), visible.status(), visible.applicationChannels(), visible.skills(),
                visible.postedAt(), visible.updatedAt(), visible.closedAt());
        return new CareerPostReportTarget(post.getTitle(), post.getAuthorUserId(), snapshot);
    }

    public PageResponse<CareerPostResponse> mine(SessionPrincipal principal, int page, int size) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.ALUMNI);
        PageValidation.check(page, size);
        var result = posts.findByAuthorUserId(actor.userId(), PageRequest.of(page, size,
                Sort.by(Sort.Order.desc("postedAt"), Sort.Order.desc("jobPostId"))));
        return page(result, actor.userId(), false);
    }

    public CareerPostResponse update(SessionPrincipal principal, long id, CareerPostRequest request) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.ALUMNI);
        LocalDate today = today();
        var input = validation.post(request, today);
        JobPost post = lockOwned(id, actor.userId());
        if (post.getStatus() != JobPostStatus.PUBLISHED || post.isExpired(today) || post.getAuthorRedactedAt() != null) {
            throw state("Only a non-expired published post may be edited.");
        }
        var skillRefs = profiles.resolveOrCreateSkillReferences(input.skills().stream().map(s -> s.name()).toList());
        var skills = new LinkedHashSet<JobSkill>();
        input.skills().forEach(skill -> skills.add(new JobSkill(skillRefs.get(skill.name()).id(), skill.required())));
        post.update(input.title(), input.companyName(), input.description(), input.qualifications(), input.location(),
                input.employmentType(), input.workMode(), input.salaryRange(), input.applicationUrl(),
                input.applicationEmail(), input.applicationDeadline(), skills, now());
        posts.flush();
        return response(post, actor.displayName(), false, false, today);
    }

    public CareerPostResponse close(SessionPrincipal principal, long id) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.ALUMNI);
        JobPost post = lockOwned(id, actor.userId());
        if (post.getStatus() == JobPostStatus.CLOSED) {
            return response(post, actor.displayName(), false, false, today());
        }
        if (post.getStatus() != JobPostStatus.PUBLISHED || post.getAuthorRedactedAt() != null) {
            throw state("This post cannot be closed.");
        }
        post.close(now());
        posts.flush();
        return response(post, actor.displayName(), false, false, today());
    }

    public SavedJobResponse save(SessionPrincipal principal, long postId, SaveJobRequest request) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        JobPost post = posts.lockById(postId).orElseThrow(() -> missing(postId));
        LocalDate today = today();
        if (!post.isActive(today)) throw state("Only an active career post may be saved.");
        if (savedJobs.existsByStudentUserIdAndJobPostJobPostId(actor.userId(), postId)) throw duplicateSave();
        String note = validation.note(request == null ? null : request.note());
        try {
            SavedJob saved = savedJobs.saveAndFlush(new SavedJob(actor.userId(), post, note, now()));
            return mapper.saved(saved, response(post, authorName(post), true, true, today));
        } catch (DataIntegrityViolationException duplicate) {
            throw duplicateSave();
        }
    }

    public void unsave(SessionPrincipal principal, long postId) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        posts.lockById(postId).orElseThrow(() -> missing(postId));
        SavedJob saved = savedJobs.lockByStudentAndPost(actor.userId(), postId)
                .orElseThrow(() -> new ResourceNotFoundException("Saved job", postId));
        savedJobs.delete(saved);
        savedJobs.flush();
    }

    public SavedJobResponse updateSavedNote(SessionPrincipal principal, long savedJobId,
            UpdateSavedNoteRequest request) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        SavedJob initial = savedJobs.findById(savedJobId)
                .filter(saved -> saved.getStudentUserId() == actor.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Saved job", savedJobId));
        long postId = initial.getJobPost().getJobPostId();
        posts.lockById(postId).orElseThrow(() -> missing(postId));
        SavedJob saved = savedJobs.lockById(savedJobId)
                .filter(item -> item.getStudentUserId() == actor.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Saved job", savedJobId));
        saved.updateNote(validation.note(request == null ? null : request.note()), now());
        savedJobs.flush();
        JobPost post = saved.getJobPost();
        return mapper.saved(saved, response(post, authorName(post), true, true, today()));
    }

    public PageResponse<SavedJobResponse> saved(SessionPrincipal principal, int page, int size) {
        var actor = requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        PageValidation.check(page, size);
        Page<SavedJob> result = savedJobs.findByStudentUserId(actor.userId(), PageRequest.of(page, size,
                Sort.by(Sort.Order.desc("savedAt"), Sort.Order.desc("savedJobId"))));
        LocalDate today = today();
        Map<Long, String> authors = authorNames(result.getContent().stream().map(SavedJob::getJobPost).toList());
        Map<Long, String> skills = skillNames(result.getContent().stream().map(SavedJob::getJobPost).toList());
        var items = result.getContent().stream().map(saved -> {
            JobPost post = saved.getJobPost();
            return mapper.saved(saved, mapper.post(post, authors.getOrDefault(post.getAuthorUserId(), "Former User"),
                    skills, today, true, true));
        }).toList();
        return new PageResponse<>(items, page, size, result.getTotalElements());
    }

    public URI application(SessionPrincipal principal, long postId, ApplicationChannel requested) {
        requireRole(accounts.lockActive(principal), PlatformRole.STUDENT);
        JobPost post = posts.lockById(postId).orElseThrow(() -> missing(postId));
        if (!post.isActive(today())) throw state("Applications are available only for active career posts.");
        boolean hasUrl = post.getApplicationUrl() != null;
        boolean hasEmail = post.getApplicationEmail() != null;
        ApplicationChannel selected = requested;
        if (selected == null && hasUrl != hasEmail) selected = hasUrl ? ApplicationChannel.URL : ApplicationChannel.EMAIL;
        if (selected == null) throw new BadRequestException("APPLICATION_CHANNEL_REQUIRED",
                "Select URL or EMAIL because this post provides both application channels.");
        if (selected == ApplicationChannel.URL && hasUrl) return URI.create(post.getApplicationUrl());
        if (selected == ApplicationChannel.EMAIL && hasEmail) return URI.create("mailto:" + post.getApplicationEmail());
        throw new BadRequestException("INVALID_APPLICATION_CHANNEL", "The selected application channel is unavailable.");
    }

    private PageResponse<CareerPostResponse> page(Page<JobPost> result, long viewerId, boolean studentViewer) {
        List<JobPost> content = result.getContent();
        Set<Long> savedIds = studentViewer && !content.isEmpty()
                ? savedJobs.findSavedPostIds(viewerId, content.stream().map(JobPost::getJobPostId).toList()) : Set.of();
        Map<Long, String> authors = authorNames(content);
        Map<Long, String> skills = skillNames(content);
        LocalDate today = today();
        var items = content.stream().map(post -> mapper.post(post,
                authors.getOrDefault(post.getAuthorUserId(), "Former User"), skills, today,
                savedIds.contains(post.getJobPostId()), studentViewer)).toList();
        return new PageResponse<>(items, result.getNumber(), result.getSize(), result.getTotalElements());
    }

    private CareerPostResponse response(JobPost post, String authorName, boolean saved, boolean studentViewer,
            LocalDate today) {
        return mapper.post(post, authorName, skillNames(List.of(post)), today, saved, studentViewer);
    }

    private Map<Long, String> authorNames(Collection<JobPost> content) {
        var ids = content.stream().map(JobPost::getAuthorUserId).collect(java.util.stream.Collectors.toSet());
        var result = new LinkedHashMap<Long, String>();
        accounts.authors(ids).forEach((id, author) -> result.put(id, author.displayName()));
        return result;
    }

    private String authorName(JobPost post) {
        return authorNames(List.of(post)).getOrDefault(post.getAuthorUserId(), "Former User");
    }

    private Map<Long, String> skillNames(Collection<JobPost> content) {
        var ids = content.stream().flatMap(post -> post.getSkills().stream()).map(JobSkill::getSkillId)
                .collect(java.util.stream.Collectors.toSet());
        return profiles.skillNames(ids);
    }

    private Specification<JobPost> activeSpecification(LocalDate today, EmploymentType employmentType,
            String location, WorkMode workMode, Long skillId) {
        return (root, query, cb) -> {
            var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
            predicates.add(cb.equal(root.get("status"), JobPostStatus.PUBLISHED));
            predicates.add(cb.greaterThanOrEqualTo(root.get("applicationDeadline"), today));
            predicates.add(cb.isNull(root.get("authorRedactedAt")));
            if (employmentType != null) predicates.add(cb.equal(root.get("employmentType"), employmentType));
            if (workMode != null) predicates.add(cb.equal(root.get("workMode"), workMode));
            if (location != null) predicates.add(cb.like(cb.lower(root.get("location")), "%" + location + "%"));
            if (skillId != null) {
                query.distinct(true);
                predicates.add(cb.equal(root.join("skills", JoinType.INNER).get("skillId"), skillId));
            }
            return cb.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
        };
    }

    private JobPost require(long id) { return posts.findById(id).orElseThrow(() -> missing(id)); }

    private JobPost lockOwned(long id, long authorId) {
        JobPost post = posts.lockById(id).orElseThrow(() -> missing(id));
        if (post.getAuthorUserId() != authorId) throw missing(id);
        return post;
    }

    private CareerAccountService.Actor requireRole(CareerAccountService.Actor actor, PlatformRole role) {
        if (actor.role() != role) throw new ForbiddenException("This Career Board operation requires role " + role + ".");
        return actor;
    }

    private LocalDate today() { return LocalDate.now(clock.withZone(CAREER_ZONE)); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
    private ResourceNotFoundException missing(long id) { return new ResourceNotFoundException("Career post", id); }
    private ConflictException state(String message) { return new ConflictException("INVALID_JOB_POST_STATE", message); }
    private ConflictException duplicateSave() {
        return new ConflictException("DUPLICATE_SAVED_JOB", "This career post is already saved.");
    }
}
