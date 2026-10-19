package com.uniconnect.club.publication.service;

import com.uniconnect.authentication.service.ClubAccountService;
import com.uniconnect.club.domain.*;
import com.uniconnect.club.repository.ClubRepository;
import com.uniconnect.club.service.ClubContextService;
import com.uniconnect.club.publication.domain.*;
import com.uniconnect.club.publication.dto.*;
import com.uniconnect.club.publication.mapper.PublicationMapper;
import com.uniconnect.club.publication.repository.PublicationRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.time.*;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;

@Service
@Transactional
public class PublicationService {
    public record PublicationRemovalEvidence(long auditId,String subjectType,long subjectId,long clubId,String actionType,LocalDateTime occurredAt) {}
    private final ClubRepository clubs;
    private final ClubAccountService accounts;
    private final ClubContextService contexts;
    private final PublicationRepository publications;
    private final PublicationMapper mapper;
    private final PublicationValidation validation;
    private final JsonMapper json;
    private final Clock clock;
    public PublicationService(ClubRepository clubs, ClubAccountService accounts, ClubContextService contexts,
            PublicationRepository publications, PublicationMapper mapper, PublicationValidation validation, JsonMapper json, Clock clock) {
        this.clubs = clubs; this.accounts = accounts; this.contexts = contexts; this.publications = publications;
        this.mapper = mapper; this.validation = validation; this.json = json; this.clock = clock;
    }
    public AnnouncementResponse createAnnouncement(SessionPrincipal actor, long clubId, AnnouncementRequest request) {
        validation.check(request);
        if (request.status() != AnnouncementStatus.UNPUBLISHED && request.status() != AnnouncementStatus.PUBLISHED)
            throw validation.invalid("New announcements must be UNPUBLISHED or PUBLISHED.");
        var op = operator(actor, clubId); requirePublishing(op.club()); var now = now(); validation.expiry(request.expiresAt(), now);
        var a = new Announcement(clubId, actor.userId(), op.assignment().getId(), request.title().strip(), request.content().strip(), request.priority(), request.expiresAt(), now);
        if (request.status() == AnnouncementStatus.PUBLISHED) a.publish(now);
        publications.insert(a); var result = mapper.announcement(a, op.club(), now);
        audit(op, a.getId(), null, "CREATED", null, null, result, now); return result;
    }
    public AnnouncementResponse editAnnouncement(SessionPrincipal actor, long clubId, long id, AnnouncementEditRequest request) {
        validation.check(request); var op = operator(actor, clubId); var a = announcement(clubId, id); owns(op, a.getAuthorAssignmentId());
        var now = now(); editable(a, now); validation.expiry(request.expiresAt(), now); var before = mapper.announcement(a, op.club(), now);
        a.edit(request.title().strip(), request.content().strip(), request.priority(), request.expiresAt(), now);
        var result = mapper.announcement(a, op.club(), now); audit(op, id, null, "EDITED", null, before, result, now); return result;
    }
    public AnnouncementResponse publish(SessionPrincipal actor, long clubId, long id) {
        var op = operator(actor, clubId); var a = announcement(clubId, id); owns(op, a.getAuthorAssignmentId()); var now = now();
        // Retries are a no-op, including no duplicate audit record.
        if (a.statusAt(now) == AnnouncementStatus.PUBLISHED) return mapper.announcement(a, op.club(), now);
        requirePublishing(op.club());
        if (a.statusAt(now) != AnnouncementStatus.UNPUBLISHED) throw state("Only unpublished announcements can be published.");
        validation.expiry(a.getExpiresAt(), now); var before = mapper.announcement(a, op.club(), now); a.publish(now);
        var result = mapper.announcement(a, op.club(), now); audit(op, id, null, "PUBLISHED", null, before, result, now); return result;
    }
    public AnnouncementResponse unpublish(SessionPrincipal actor, long clubId, long id, PublicationActionRequest request) {
        validation.check(request); var op = operator(actor, clubId); var a = announcement(clubId, id); owns(op, a.getAuthorAssignmentId()); var now = now();
        if (a.statusAt(now) == AnnouncementStatus.UNPUBLISHED) return mapper.announcement(a, op.club(), now);
        if (a.statusAt(now) != AnnouncementStatus.PUBLISHED) throw state("Only published, non-expired announcements can be unpublished.");
        var before = mapper.announcement(a, op.club(), now); a.unpublish(now); var result = mapper.announcement(a, op.club(), now);
        audit(op, id, null, "UNPUBLISHED", request.reason().strip(), before, result, now); return result;
    }
    public AnnouncementResponse removeAnnouncement(SessionPrincipal actor, long clubId, long id, PublicationActionRequest request) {
        validation.check(request); var op = operator(actor, clubId); var a = announcement(clubId, id); owns(op, a.getAuthorAssignmentId()); var now = now();
        if (a.statusAt(now) == AnnouncementStatus.REMOVED) return mapper.announcement(a, op.club(), now);
        var before = mapper.announcement(a, op.club(), now); a.remove(now); var result = mapper.announcement(a, op.club(), now);
        audit(op, id, null, "REMOVED", request.reason().strip(), before, result, now); return result;
    }
    public EventResponse createEvent(SessionPrincipal actor, long clubId, EventRequest request) {
        validation.event(request); var op = operator(actor, clubId); requirePublishing(op.club()); var now = now();
        var e = publications.insert(new ClubEvent(clubId, actor.userId(), op.assignment().getId(), request.title().strip(), request.description().strip(),
                validation.optional(request.location()), validation.url(request.registrationUrl()), request.registrationDeadline(), request.startsAt(), request.endsAt(), now));
        var result = mapper.event(e, op.club(), now); audit(op, null, e.getId(), "CREATED", null, null, result, now); return result;
    }
    public EventResponse editEvent(SessionPrincipal actor, long clubId, long id, EventRequest request) {
        validation.event(request); var op = operator(actor, clubId); var e = event(clubId, id); owns(op, e.getAuthorAssignmentId()); var now = now();
        if (e.getStatus() != EventStatus.PUBLISHED || e.timingAt(now) == EventTiming.PAST) throw state("Removed or past events cannot be edited.");
        var before = mapper.event(e, op.club(), now);
        e.edit(request.title().strip(), request.description().strip(), validation.optional(request.location()), validation.url(request.registrationUrl()),
                request.registrationDeadline(), request.startsAt(), request.endsAt(), now);
        var result = mapper.event(e, op.club(), now); audit(op, null, id, "EDITED", null, before, result, now); return result;
    }
    public EventResponse removeEvent(SessionPrincipal actor, long clubId, long id, PublicationActionRequest request) {
        validation.check(request); var op = operator(actor, clubId); var e = event(clubId, id); owns(op, e.getAuthorAssignmentId()); var now = now();
        if (e.getStatus() == EventStatus.REMOVED) return mapper.event(e, op.club(), now);
        var before = mapper.event(e, op.club(), now); e.remove(now); var result = mapper.event(e, op.club(), now);
        audit(op, null, id, "REMOVED", request.reason().strip(), before, result, now); return result;
    }
    @Transactional(readOnly = true)
    public PageResponse<AnnouncementResponse> announcements(Long clubId, String category, AnnouncementPriority priority,
            LocalDateTime from, LocalDateTime before, int page, int size) {
        PageValidation.check(page, size); validation.id(clubId); validation.range(from, before); var now = now();
        var rows = publications.announcements(clubId, validation.category(category), priority, from, before, null, false, null, now, page, size);
        return new PageResponse<>(rows.items().stream().map(a -> mapper.announcement(a, clubs.find(a.getClubId()), now)).toList(), page, size, rows.total());
    }
    @Transactional(readOnly = true)
    public AnnouncementResponse publicAnnouncement(long id) {
        var a = publications.announcement(id); var now = now();
        if (a == null || a.statusAt(now) != AnnouncementStatus.PUBLISHED) throw new ResourceNotFoundException("Announcement", id);
        return mapper.announcement(a, visibleClub(a.getClubId()), now);
    }
    @Transactional(readOnly = true)
    public PageResponse<EventResponse> events(Long clubId, String category, EventTiming timing, boolean history, int page, int size) {
        PageValidation.check(page, size); validation.id(clubId);
        if (history && clubId == null) throw validation.invalid("Event history requires a clubId.");
        if (!history && timing == EventTiming.PAST) throw validation.invalid("Use club event history to browse past events.");
        if (history) visibleClub(clubId);
        var now = now(); var rows = publications.events(clubId, validation.category(category), null, false, null, timing, history, now, page, size);
        return new PageResponse<>(rows.items().stream().map(e -> mapper.event(e, clubs.find(e.getClubId()), now)).toList(), page, size, rows.total());
    }
    @Transactional(readOnly = true)
    public EventResponse publicEvent(long id) {
        var e = publications.event(id);
        if (e == null || e.getStatus() != EventStatus.PUBLISHED) throw new ResourceNotFoundException("Event", id);
        return mapper.event(e, visibleClub(e.getClubId()), now());
    }
    public AnnouncementResponse reportableAnnouncement(SessionPrincipal actor,long id){
        var a=publications.announcement(id);if(a==null)throw new ResourceNotFoundException("Announcement",id);
        var club=visibleClub(a.getClubId());accounts.lock(actor,List.of());var now=now();
        if(a.statusAt(now)==AnnouncementStatus.PUBLISHED)return mapper.announcement(a,club,now);
        var assignment=clubs.current(club.getId(),actor.userId()).orElseThrow(()->new ResourceNotFoundException("Announcement",id));
        if(assignment.getRole()!=ClubRole.CLUB_ADMINISTRATOR&&assignment.getId()!=a.getAuthorAssignmentId())
            throw new ResourceNotFoundException("Announcement",id);
        return mapper.announcement(a,club,now);
    }
    public EventResponse reportableEvent(SessionPrincipal actor,long id){
        var e=publications.event(id);if(e==null)throw new ResourceNotFoundException("Event",id);
        var club=visibleClub(e.getClubId());accounts.lock(actor,List.of());var now=now();
        if(e.getStatus()==EventStatus.PUBLISHED)return mapper.event(e,club,now);
        var assignment=clubs.current(club.getId(),actor.userId()).orElseThrow(()->new ResourceNotFoundException("Event",id));
        if(assignment.getRole()!=ClubRole.CLUB_ADMINISTRATOR&&assignment.getId()!=e.getAuthorAssignmentId())
            throw new ResourceNotFoundException("Event",id);
        return mapper.event(e,club,now);
    }
    @Transactional(readOnly=true)
    public PublicationRemovalEvidence verifyRemovalEvidence(long auditId){
        var audit=publications.audit(auditId);
        if(audit==null||!audit.getAction().equals("REMOVED")||(audit.getAnnouncementId()==null)==(audit.getEventId()==null))
            throw new ConflictException("INVALID_ACTION_EVIDENCE","Publication evidence must reference one removal audit.");
        String type=audit.getAnnouncementId()!=null?"ANNOUNCEMENT":"EVENT";
        long subject=audit.getAnnouncementId()!=null?audit.getAnnouncementId():audit.getEventId();
        return new PublicationRemovalEvidence(audit.getId(),type,subject,audit.getClubId(),audit.getAction(),audit.getCreatedAt());
    }
    public PageResponse<AnnouncementResponse> managedAnnouncements(SessionPrincipal actor, long clubId, AnnouncementStatus status, int page, int size) {
        PageValidation.check(page, size); var op = operator(actor, clubId); var now = now();
        var rows = publications.announcements(clubId, null, null, null, null, ownerFilter(op), true, status, now, page, size);
        return new PageResponse<>(rows.items().stream().map(a -> mapper.announcement(a, op.club(), now)).toList(), page, size, rows.total());
    }
    public AnnouncementResponse managedAnnouncement(SessionPrincipal actor, long clubId, long id) {
        var op = operator(actor, clubId); var a = announcement(clubId, id); owns(op, a.getAuthorAssignmentId()); return mapper.announcement(a, op.club(), now());
    }
    public PageResponse<EventResponse> managedEvents(SessionPrincipal actor, long clubId, EventStatus status, EventTiming timing, int page, int size) {
        PageValidation.check(page, size); var op = operator(actor, clubId); var now = now();
        var rows = publications.events(clubId, null, ownerFilter(op), true, status, timing, false, now, page, size);
        return new PageResponse<>(rows.items().stream().map(e -> mapper.event(e, op.club(), now)).toList(), page, size, rows.total());
    }
    public EventResponse managedEvent(SessionPrincipal actor, long clubId, long id) {
        var op = operator(actor, clubId); var e = event(clubId, id); owns(op, e.getAuthorAssignmentId()); return mapper.event(e, op.club(), now());
    }
    public PageResponse<PublicationAuditResponse> auditHistory(SessionPrincipal actor, long clubId, int page, int size) {
        PageValidation.check(page, size); var op = operator(actor, clubId);
        if (op.assignment().getRole() != ClubRole.CLUB_ADMINISTRATOR) throw new ForbiddenException("Publication audit requires this club's administrator context.");
        var rows = publications.audit(clubId, page, size); return new PageResponse<>(rows.items().stream().map(mapper::audit).toList(), page, size, rows.total());
    }
    private record Operator(Club club, ClubRoleAssignment assignment) {}
    private Operator operator(SessionPrincipal actor, long clubId) {
        // Same lock order as revoke/replace: club, actor account, then session/assignment validation.
        var club = clubs.lock(clubId);
        if (club == null || club.getStatus() == ClubStatus.REMOVED) throw new ResourceNotFoundException("Club", clubId);
        var account = accounts.lock(actor, List.of()).get(actor.userId());
        return new Operator(club, contexts.requireOperator(actor, club, account));
    }
    private void owns(Operator op, long assignment) {
        if (op.assignment().getRole() != ClubRole.CLUB_ADMINISTRATOR && op.assignment().getId() != assignment)
            throw new ForbiddenException("Representatives may manage only publications authored under their current assignment.");
    }
    private Long ownerFilter(Operator op) { return op.assignment().getRole() == ClubRole.CLUB_ADMINISTRATOR ? null : op.assignment().getId(); }
    private void requirePublishing(Club club) {
        if (club.getStatus() != ClubStatus.ACTIVE) throw new ForbiddenException("Publishing is suspended for this club.");
    }
    private Club visibleClub(long id) {
        var club = clubs.find(id);
        if (club == null || club.getStatus() == ClubStatus.REMOVED) throw new ResourceNotFoundException("Club", id);
        return club;
    }
    private Announcement announcement(long club, long id) {
        var a = publications.announcement(id);
        if (a == null || a.getClubId() != club) throw new ResourceNotFoundException("Announcement", id); return a;
    }
    private ClubEvent event(long club, long id) {
        var e = publications.event(id);
        if (e == null || e.getClubId() != club) throw new ResourceNotFoundException("Event", id); return e;
    }
    private void editable(Announcement a, LocalDateTime now) {
        if (a.statusAt(now) != AnnouncementStatus.UNPUBLISHED && a.statusAt(now) != AnnouncementStatus.PUBLISHED)
            throw state("Expired or removed announcements cannot be edited.");
    }
    private void audit(Operator op, Long announcement, Long event, String action, String reason, Object before, Object after, LocalDateTime now) {
        publications.insert(new PublicationAudit(op.club().getId(), announcement, event, op.assignment().getUserId(), op.assignment().getId(), action, reason,
                before == null ? null : json.writeValueAsString(before), json.writeValueAsString(after), now));
    }
    private ConflictException state(String message) { return new ConflictException("INVALID_PUBLICATION_STATE", message); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC); }
}
