package com.uniconnect.discovery.service;
import com.uniconnect.discovery.dto.*;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.service.MemberProfileService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.PlatformRole;
import com.uniconnect.shared.security.SessionPrincipal;
import java.util.*;
import org.springframework.stereotype.Service;

/** Discovery delegates all field visibility to the profile module's public boundary. */
@Service
public class DiscoveryService {
    private final MemberProfileService profiles;
    private final CandidateSearchValidation candidateValidation;
    public DiscoveryService(MemberProfileService profiles, CandidateSearchValidation candidateValidation) {
        this.profiles = profiles;
        this.candidateValidation = candidateValidation;
    }
    public PageResponse<MemberProfileResponse> search(SessionPrincipal actor, MemberSearch search) { return profiles.search(actor, search); }
    public MemberProfileResponse view(SessionPrincipal actor, long userId) { return profiles.view(actor, userId); }

    public PageResponse<ProjectCandidateResponse> searchCandidates(SessionPrincipal actor, CandidateSearch request,
            Collection<Long> excluded) {
        CandidateSearch criteria = candidateValidation.normalize(request);
        var memberSearch = new MemberSearch(null, PlatformRole.STUDENT, criteria.departmentId(), null,
                criteria.requiredSkills(), criteria.yearOfStudy(), criteria.projectAvailable(), null,
                null, null, null, criteria.sort(), criteria.page(), criteria.size());
        var result = profiles.search(actor, memberSearch, excluded);
        var items = result.items().stream().map(profile -> candidate(profile, criteria)).toList();
        return new PageResponse<>(items, result.page(), result.size(), result.totalElements());
    }

    private ProjectCandidateResponse candidate(MemberProfileResponse profile, CandidateSearch criteria) {
        var details = Objects.requireNonNull(profile.details(), "Candidate detail visibility must be enforced by search");
        Set<String> visible = new HashSet<>(details.skills());
        var relevant = new ArrayList<CandidateSkillResponse>();
        criteria.requiredSkills().stream().filter(visible::contains)
                .forEach(skill -> relevant.add(new CandidateSkillResponse(skill, CandidateSkillKind.REQUIRED)));
        criteria.optionalSkills().stream().filter(visible::contains)
                .forEach(skill -> relevant.add(new CandidateSkillResponse(skill, CandidateSkillKind.OPTIONAL)));
        return new ProjectCandidateResponse(profile.userId(), profile.fullName(), profile.profilePhotoUrl(),
                profile.department(), profile.programme(), details.student().yearOfStudy(),
                details.student().projectAvailability(), List.copyOf(relevant), profile.connection());
    }
}
