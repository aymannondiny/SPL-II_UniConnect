package com.uniconnect.discovery.service;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.service.MemberProfileService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Service;

/** Discovery delegates all field visibility to the profile module's public boundary. */
@Service
public class DiscoveryService {
    private final MemberProfileService profiles;
    public DiscoveryService(MemberProfileService profiles) { this.profiles = profiles; }
    public PageResponse<MemberProfileResponse> search(SessionPrincipal actor, MemberSearch search) { return profiles.search(actor, search); }
    public MemberProfileResponse view(SessionPrincipal actor, long userId) { return profiles.view(actor, userId); }
}
