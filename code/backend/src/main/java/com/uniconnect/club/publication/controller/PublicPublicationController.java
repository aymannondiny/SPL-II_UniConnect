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
@RequestMapping("/api/v1")
@Tag(name = "Public club announcements and events")
@ApiResponse(responseCode = "200", description = "Public publication data", useReturnTypeSchema = true)
@ApiResponse(responseCode = "400", description = "Invalid publication fields or pagination", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Authentication required", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Club role or selected context is insufficient", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Publication or club unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Publication state does not permit this action", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class PublicPublicationController {
    private final PublicationService publications;
    public PublicPublicationController(PublicationService publications) { this.publications = publications; }
    @GetMapping("/announcements")
    @Operation(summary = "Browse published, non-expired announcements", description = "Public access. Filters combine; category matches exactly ignoring case. UTC publication range is [publishedFrom, publishedBefore). Newest first; page 0+, size 1–50.")
    public ResponseEntity<PageResponse<AnnouncementResponse>> announcements(@RequestParam(required = false) Long clubId,
            @RequestParam(required = false) String category, @RequestParam(required = false) AnnouncementPriority priority,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime publishedFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime publishedBefore,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.announcements(clubId, category, priority, publishedFrom, publishedBefore, page, size));
    }
    @GetMapping("/announcements/{id}")
    @Operation(summary = "Read a public announcement", description = "Draft, expired and removed announcements return 404.")
    public ResponseEntity<AnnouncementResponse> announcement(@PathVariable long id) { return ok(publications.publicAnnouncement(id)); }
    @GetMapping("/events")
    @Operation(summary = "Browse current events", description = "Public UPCOMING/ACTIVE events, ordered by start time then ID. ACTIVE includes the exact start and end instants. Optional club, category and timing filters.")
    public ResponseEntity<PageResponse<EventResponse>> events(@RequestParam(required = false) Long clubId,
            @RequestParam(required = false) String category, @RequestParam(required = false) EventTiming timing,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.events(clubId, category, timing, false, page, size));
    }
    @GetMapping("/events/{id}")
    @Operation(summary = "Read a current or past published event")
    public ResponseEntity<EventResponse> event(@PathVariable long id) { return ok(publications.publicEvent(id)); }
    @GetMapping("/clubs/{clubId}/events/history")
    @Operation(summary = "Browse a club's past published events", description = "Public history, ordered by end time descending then ID. Removed events and removed clubs are excluded.")
    public ResponseEntity<PageResponse<EventResponse>> history(@PathVariable long clubId,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(publications.events(clubId, null, EventTiming.PAST, true, page, size));
    }
    private <T> ResponseEntity<T> ok(T result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
}
