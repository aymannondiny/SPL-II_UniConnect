package com.uniconnect.club.service;

import com.uniconnect.authentication.service.ClubAccountService;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.club.repository.ClubCreationRequestRepository;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import java.time.*;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ClubCreationRequestService {
    private final ClubCreationRequestRepository requests;
    private final ClubAccountService accounts;
    private final ClubRepository clubRecords;
    private final ClubContextService contexts;
    private final ClubService clubs;
    private final ClubValidation validation;
    private final Clock clock;

    public ClubCreationRequestService(ClubCreationRequestRepository requests, ClubAccountService accounts, ClubRepository clubRecords,
            ClubContextService contexts, ClubService clubs, ClubValidation validation, Clock clock) {
        this.requests = requests; this.accounts = accounts; this.clubRecords = clubRecords; this.contexts = contexts;
        this.clubs = clubs; this.validation = validation; this.clock = clock;
    }
    public ClubCreationRequestResponse submit(SessionPrincipal actor, ClubCreationRequestSubmission body) {
        validation.check(body);
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        if (!account.eligibleStudent()) throw new ForbiddenException("Only an active student may request a club.");
        String name = body.clubName().strip();
        if (clubRecords.nameExists(Club.key(name))) throw new ConflictException("CLUB_NAME_EXISTS", "A club with this name already exists.");
        var now = now();
        var request = requests.insert(new ClubCreationRequest(actor.userId(), name, body.category().strip(),
                body.description().strip(), validation.logo(body.logoUrl()), validation.optional(body.contactEmail()), now));
        return map(request);
    }
    public List<ClubCreationRequestResponse> mine(SessionPrincipal actor) {
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        if (!account.eligibleStudent()) throw new ForbiddenException("Only an active student may view club requests.");
        return requests.owned(actor.userId()).stream().map(this::map).toList();
    }
    public List<ClubCreationRequestResponse> review(SessionPrincipal actor, ClubCreationRequestStatus status) {
        var account = accounts.lock(actor, List.of()).get(actor.userId()); contexts.requireSystem(actor, account);
        return requests.review(status).stream().map(this::map).toList();
    }
    public ClubCreationRequestResponse approve(SessionPrincipal actor, long id) {
        var request = requests.lock(id);
        if (request == null) throw new ResourceNotFoundException("Club creation request", id);
        if (request.getStatus() != ClubCreationRequestStatus.PENDING)
            throw new ConflictException("REQUEST_ALREADY_DECIDED", "This club request has already been processed.");
        var account = accounts.lock(actor, List.of(request.getRequesterUserId())).get(actor.userId());
        contexts.requireSystem(actor, account);
        var created = clubs.create(actor, new CreateClubRequest(request.getClubName(), request.getCategory(),
                request.getDescription(), request.getLogoUrl(), request.getContactEmail(), request.getRequesterUserId()));
        request.approve(actor.userId(), created.id(), now());
        return map(request);
    }
    public ClubCreationRequestResponse reject(SessionPrincipal actor, long id, ClubCreationRequestDecision body) {
        validation.check(body);
        var request = requests.lock(id);
        if (request == null) throw new ResourceNotFoundException("Club creation request", id);
        if (request.getStatus() != ClubCreationRequestStatus.PENDING)
            throw new ConflictException("REQUEST_ALREADY_DECIDED", "This club request has already been processed.");
        var account = accounts.lock(actor, List.of()).get(actor.userId()); contexts.requireSystem(actor, account);
        String reason = validation.optional(body.reason());
        request.reject(actor.userId(), reason, now());
        return map(request);
    }
    private ClubCreationRequestResponse map(ClubCreationRequest request) {
        return new ClubCreationRequestResponse(request.getId(), request.getRequesterUserId(),
                accounts.displayName(request.getRequesterUserId()), request.getClubName(), request.getCategory(),
                request.getDescription(), request.getLogoUrl(), request.getContactEmail(), request.getStatus(),
                request.getCreatedAt(), request.getDecidedAt(), request.getDecidedBy(),
                request.getRejectionReason(), request.getClubId());
    }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
