package com.uniconnect.profile.service;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.profile.dto.PrivacyRequest;
import com.uniconnect.profile.repository.PersonalProfileRepository;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ProfilePrivacyService {
    private final ProfileAccountService accounts;
    private final PersonalProfileRepository profiles;
    private final Clock clock;
    public ProfilePrivacyService(ProfileAccountService accounts, PersonalProfileRepository profiles, Clock clock) {
        this.accounts = accounts; this.profiles = profiles; this.clock = clock;
    }
    public PrivacyRequest get(SessionPrincipal actor) {
        accounts.lockActiveAccount(actor);
        return new PrivacyRequest(profiles.findByUserUserId(actor.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Personal profile", actor.userId())).getDetailsVisibility());
    }
    public PrivacyRequest update(SessionPrincipal actor, PrivacyRequest request) {
        accounts.lockActiveAccount(actor);
        if (request == null || request.detailsVisibility() == null)
            throw new BadRequestException("INVALID_VISIBILITY", "Select a details visibility.");
        var profile = profiles.findByUserUserId(actor.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Personal profile", actor.userId()));
        profile.setDetailsVisibility(request.detailsVisibility(), LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC));
        return new PrivacyRequest(profile.getDetailsVisibility());
    }
}
