package com.uniconnect.club.publication.controller;

import com.uniconnect.club.publication.domain.*;
import com.uniconnect.club.publication.dto.*;
import com.uniconnect.club.publication.service.PublicationService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/clubs/{clubId}/publications")
@Tag(name = "Club publication management")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid publication fields or pagination", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Authentication required", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Club role or selected context is insufficient", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Publication or club unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Publication state does not permit this action", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ClubPublicationController {
    private final PublicationService publications;
    public ClubPublicationController(PublicationService publications) { this.publications = publications; }
    @PostMapping("/announcements")
    @Operation(summary = "Create a draft or publish an announcement", description = "Selected current CLUB assignment required. Club must be ACTIVE. Initial status: UNPUBLISHED or PUBLISHED. Dates are UTC.")
    @ApiResponse(responseCode = "201", description = "Announcement created", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> createAnnouncement(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId,
            @Valid @RequestBody AnnouncementRequest request) { return created(publications.createAnnouncement(actor, clubId, request)); }
    @GetMapping("/announcements")
    @Operation(summary = "Manage club announcements", description = "Administrator sees all; representatives see only their exact current assignment's publications. Omit status for all states, including expired/removed.")
    @ApiResponse(responseCode = "200", description = "Managed announcements", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<AnnouncementResponse>> announcements(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId,
            @RequestParam(required = false) AnnouncementStatus status, @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.managedAnnouncements(actor, clubId, status, page, size));
    }
    @GetMapping("/announcements/{id}")
    @Operation(summary = "Read a managed announcement, including draft or retained history")
    @ApiResponse(responseCode = "200", description = "Managed announcement", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> announcement(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id) {
        return ok(publications.managedAnnouncement(actor, clubId, id));
    }
    @PutMapping("/announcements/{id}")
    @Operation(summary = "Edit an unpublished or published announcement", description = "Full field replacement. Null expiresAt clears expiry; expired/removed items cannot be edited. Authorship never changes.")
    @ApiResponse(responseCode = "200", description = "Announcement updated", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> editAnnouncement(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id,
            @Valid @RequestBody AnnouncementEditRequest request) { return ok(publications.editAnnouncement(actor, clubId, id, request)); }
    @PostMapping("/announcements/{id}/publish")
    @Operation(summary = "Publish an unpublished announcement", description = "ACTIVE club required. Repeating an already-published request is a no-op. Expired/removed items cannot be republished.")
    @ApiResponse(responseCode = "200", description = "Announcement published", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> publish(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id) {
        return ok(publications.publish(actor, clubId, id));
    }
    @PostMapping("/announcements/{id}/unpublish")
    @Operation(summary = "Unpublish with confirmation and reason", description = "Retains ID, authorship, previous publication time and audit history.")
    @ApiResponse(responseCode = "200", description = "Announcement unpublished", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> unpublish(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id,
            @Valid @RequestBody PublicationActionRequest request) { return ok(publications.unpublish(actor, clubId, id, request)); }
    @PostMapping("/announcements/{id}/remove")
    @Operation(summary = "Soft-remove an announcement with confirmation and reason")
    @ApiResponse(responseCode = "200", description = "Announcement removed", useReturnTypeSchema = true)
    public ResponseEntity<AnnouncementResponse> removeAnnouncement(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id,
            @Valid @RequestBody PublicationActionRequest request) { return ok(publications.removeAnnouncement(actor, clubId, id, request)); }
    @PostMapping("/events")
    @Operation(summary = "Publish an informational event", description = "ACTIVE club and selected current assignment required. endsAt > startsAt. Registration URL is optional HTTPS metadata; this API does not register attendees.")
    @ApiResponse(responseCode = "201", description = "Event published", useReturnTypeSchema = true)
    public ResponseEntity<EventResponse> createEvent(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId,
            @Valid @RequestBody EventRequest request) { return created(publications.createEvent(actor, clubId, request)); }
    @GetMapping("/events")
    @Operation(summary = "Manage current, past or removed events", description = "Administrator sees all; representatives see only their current assignment's events. Omit filters for all states/timings.")
    @ApiResponse(responseCode = "200", description = "Managed events", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<EventResponse>> events(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId,
            @RequestParam(required = false) EventStatus status, @RequestParam(required = false) EventTiming timing,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.managedEvents(actor, clubId, status, timing, page, size));
    }
    @GetMapping("/events/{id}")
    @Operation(summary = "Read a managed event")
    @ApiResponse(responseCode = "200", description = "Managed event", useReturnTypeSchema = true)
    public ResponseEntity<EventResponse> event(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id) {
        return ok(publications.managedEvent(actor, clubId, id));
    }
    @PutMapping("/events/{id}")
    @Operation(summary = "Edit a current event", description = "Full field replacement. Past and removed events cannot be edited; historical identity and authorship are retained.")
    @ApiResponse(responseCode = "200", description = "Event updated", useReturnTypeSchema = true)
    public ResponseEntity<EventResponse> editEvent(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id,
            @Valid @RequestBody EventRequest request) { return ok(publications.editEvent(actor, clubId, id, request)); }
    @PostMapping("/events/{id}/remove")
    @Operation(summary = "Soft-remove a current or past event with confirmation and reason")
    @ApiResponse(responseCode = "200", description = "Event removed", useReturnTypeSchema = true)
    public ResponseEntity<EventResponse> removeEvent(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId, @PathVariable long id,
            @Valid @RequestBody PublicationActionRequest request) { return ok(publications.removeEvent(actor, clubId, id, request)); }
    @GetMapping("/audit")
    @Operation(summary = "Read immutable publication change history", description = "Selected club administrator only. Snapshots are JSON strings; newest changes first.")
    @ApiResponse(responseCode = "200", description = "Publication audit history", useReturnTypeSchema = true)
    public ResponseEntity<PageResponse<PublicationAuditResponse>> audit(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long clubId,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.auditHistory(actor, clubId, page, size));
    }
    private <T> ResponseEntity<T> ok(T result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
    private <T> ResponseEntity<T> created(T result) { return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(result); }
}
