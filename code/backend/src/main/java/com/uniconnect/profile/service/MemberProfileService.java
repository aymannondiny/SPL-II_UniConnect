package com.uniconnect.profile.service;

import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.dto.ConnectionSummary;
import com.uniconnect.connection.service.ConnectionQueryService;
import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.mapper.MemberProfileMapper;
import com.uniconnect.profile.repository.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.*;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class MemberProfileService {
    private final ProfileAccountService accounts;
    private final PersonalProfileRepository profiles;
    private final MemberSearchRepository search;
    private final MemberSearchValidation validation;
    private final ConnectionQueryService connections;
    private final MemberProfileMapper mapper;
    public MemberProfileService(ProfileAccountService accounts, PersonalProfileRepository profiles,
            MemberSearchRepository search, MemberSearchValidation validation, ConnectionQueryService connections, MemberProfileMapper mapper) {
        this.accounts = accounts; this.profiles = profiles; this.search = search;
        this.validation = validation; this.connections = connections; this.mapper = mapper;
    }
    public MemberProfileResponse view(SessionPrincipal actor, long userId) {
        accounts.lockActiveAccount(actor);
        var profile = profiles.findByUserUserId(userId).filter(p -> p.getUser().canPerformProtectedAction()
                && p.getUser().getPlatformRole() != PlatformRole.SYSTEM_ADMIN)
                .orElseThrow(() -> new ResourceNotFoundException("Member profile", userId));
        var relation = connections.relationships(actor.userId()).get(userId);
        return response(profile, actor.userId(), relation, profiles.findByUserUserId(actor.userId()).orElse(null));
    }
    public PageResponse<MemberProfileResponse> search(SessionPrincipal actor, MemberSearch request) {
        accounts.lockActiveAccount(actor);
        var criteria = validation.normalize(request);
        var relations = connections.relationships(actor.userId());
        var peers = relations.entrySet().stream().filter(e -> e.getValue().status() == ConnectionStatus.ACCEPTED).map(Map.Entry::getKey).toList();
        var result = search.search(actor.userId(), peers, criteria);
        var own = profiles.findByUserUserId(actor.userId()).orElse(null);
        return new PageResponse<>(result.items().stream().map(p -> response(p, actor.userId(), relations.get(p.getUser().getUserId()), own)).toList(),
                result.page(), result.size(), result.totalElements());
    }
    private MemberProfileResponse response(PersonalProfile p, long viewer, ConnectionSummary relation, PersonalProfile own) {
        boolean visible = p.getUser().getUserId() == viewer || p.getDetailsVisibility() == ProfileVisibility.ALL_MEMBERS
                || (relation != null && relation.status() == ConnectionStatus.ACCEPTED);
        return mapper.response(p, visible, relation, own);
    }
}
