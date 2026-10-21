package com.uniconnect.project.service;

import com.uniconnect.authentication.service.ProjectAccountService;
import com.uniconnect.discovery.dto.*;
import com.uniconnect.discovery.service.DiscoveryService;
import com.uniconnect.profile.service.ProfileQueryService;
import com.uniconnect.project.domain.*;
import com.uniconnect.project.repository.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ProjectCandidateService {
    private static final ZoneId PROJECT_ZONE = ZoneId.of("Asia/Dhaka");
    private final ProjectRepository projects;
    private final ProjectMembershipRepository memberships;
    private final ProjectApplicationRepository applications;
    private final ProjectAccountService accounts;
    private final ProfileQueryService profiles;
    private final DiscoveryService discovery;
    private final Clock clock;

    public ProjectCandidateService(ProjectRepository projects, ProjectMembershipRepository memberships,
            ProjectApplicationRepository applications, ProjectAccountService accounts,
            ProfileQueryService profiles, DiscoveryService discovery, Clock clock) {
        this.projects = projects;
        this.memberships = memberships;
        this.applications = applications;
        this.accounts = accounts;
        this.profiles = profiles;
        this.discovery = discovery;
        this.clock = clock;
    }

    public PageResponse<ProjectCandidateResponse> standalone(SessionPrincipal principal, CandidateSearch request) {
        requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        return discovery.searchCandidates(principal, request, Set.of());
    }

    public PageResponse<ProjectCandidateResponse> forProject(SessionPrincipal principal, long projectId,
            Long departmentId, Integer yearOfStudy, Boolean projectAvailable, String sort, int page, int size) {
        var actor = requireEligible(accounts.lock(principal, List.of()).get(principal.userId()));
        Project project = projects.findById(projectId).filter(p -> p.getStatus() != ProjectStatus.DELETED)
                .orElseThrow(() -> missing(projectId));
        if (project.getCreatorUserId() != actor.id()) throw missing(projectId);
        long membershipCount = memberships.countByProjectProjectId(projectId);
        if (project.getStatus() != ProjectStatus.OPEN || project.expired(today())
                || membershipCount >= project.getTeamSizeLimit())
            throw new ConflictException("INVALID_PROJECT_STATE",
                    "Candidate search requires open, unexpired recruitment with a vacancy.");

        Map<Long, String> names = profiles.skillNames(project.getSkills().stream()
                .map(ProjectSkill::getSkillId).toList());
        List<String> required = project.getSkills().stream().filter(ProjectSkill::isRequired)
                .map(skill -> names.get(skill.getSkillId())).filter(Objects::nonNull).toList();
        List<String> optional = project.getSkills().stream().filter(skill -> !skill.isRequired())
                .map(skill -> names.get(skill.getSkillId())).filter(Objects::nonNull).toList();
        var excluded = new HashSet<>(memberships.memberUserIds(projectId));
        excluded.addAll(applications.applicantUserIds(projectId));
        return discovery.searchCandidates(principal, new CandidateSearch(required, optional, departmentId,
                yearOfStudy, projectAvailable, sort, page, size), excluded);
    }

    private ProjectAccountService.Account requireEligible(ProjectAccountService.Account account) {
        if (account == null || !account.eligibleStudent())
            throw new ForbiddenException("Project Teammate Finder requires an ACTIVE, non-anonymized STUDENT account.");
        return account;
    }

    private LocalDate today() { return LocalDate.now(clock.withZone(PROJECT_ZONE)); }
    private ResourceNotFoundException missing(long id) { return new ResourceNotFoundException("Project", id); }
}
