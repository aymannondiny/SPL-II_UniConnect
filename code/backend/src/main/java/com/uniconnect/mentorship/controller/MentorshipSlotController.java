package com.uniconnect.mentorship.controller;

import com.uniconnect.mentorship.domain.SlotStatus;
import com.uniconnect.mentorship.domain.SlotMode;
import com.uniconnect.mentorship.dto.*;
import com.uniconnect.mentorship.service.MentorshipSlotService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/mentorship/slots")
@Tag(name = "Peer Mentorship - Slots")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting mentorship slot state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class MentorshipSlotController {

    private final MentorshipSlotService slotService;

    public MentorshipSlotController(MentorshipSlotService slotService) {
        this.slotService = slotService;
    }

    @PostMapping
    @Operation(summary = "Publish a new mentorship slot", description = "Mentors can create mentorship sessions for students to join.")
    @ApiResponse(responseCode = "201", description = "Mentorship slot created", content = @Content(schema = @Schema(implementation = MentorshipSlotResponse.class)))
    public ResponseEntity<MentorshipSlotResponse> create(
            @AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody CreateSlotRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .cacheControl(CacheControl.noStore())
                .body(slotService.createSlot(actor, request));
    }

    @GetMapping
    @Operation(summary = "Browse open mentorship slots", description = "Search and filter open or full mentorship slots.")
    @ApiResponse(responseCode = "200", description = "Paginated list of mentorship slots")
    public ResponseEntity<PageResponse<MentorshipSlotSummaryResponse>> browse(
            @AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) String topic,
            @RequestParam(required = false) SlotStatus status,
            @RequestParam(required = false) SlotMode mode,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.browseSlots(actor, topic, status, mode, page, size));
    }

    @GetMapping("/{slotId}")
    @Operation(summary = "View mentorship slot details")
    @ApiResponse(responseCode = "200", description = "Mentorship slot details", content = @Content(schema = @Schema(implementation = MentorshipSlotResponse.class)))
    public ResponseEntity<MentorshipSlotResponse> getSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.getSlot(actor, slotId));
    }

    @PutMapping("/{slotId}")
    @Operation(summary = "Update mentorship slot details", description = "Only the slot creator can update slot details.")
    @ApiResponse(responseCode = "200", description = "Updated mentorship slot", content = @Content(schema = @Schema(implementation = MentorshipSlotResponse.class)))
    public ResponseEntity<MentorshipSlotResponse> updateSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId,
            @Valid @RequestBody UpdateSlotRequest request
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.updateSlot(actor, slotId, request));
    }

    @PostMapping("/{slotId}/join")
    @Operation(summary = "Join an open mentorship slot", description = "Students can enroll in open mentorship slots with capacity.")
    @ApiResponse(responseCode = "200", description = "Enrollment confirmed", content = @Content(schema = @Schema(implementation = MentorshipEnrollmentResponse.class)))
    public ResponseEntity<MentorshipEnrollmentResponse> joinSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId,
            @Valid @RequestBody(required = false) EnrollSlotRequest request
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.joinSlot(actor, slotId, request));
    }

    @PostMapping("/{slotId}/leave")
    @Operation(summary = "Leave a mentorship slot", description = "Enrolled students can leave a slot, freeing up capacity.")
    @ApiResponse(responseCode = "200", description = "Enrollment left", content = @Content(schema = @Schema(implementation = MentorshipEnrollmentResponse.class)))
    public ResponseEntity<MentorshipEnrollmentResponse> leaveSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.leaveSlot(actor, slotId));
    }

    @PostMapping("/{slotId}/close")
    @Operation(summary = "Close mentorship slot enrollment", description = "Mentor can close the slot to prevent new enrollees.")
    @ApiResponse(responseCode = "200", description = "Slot closed", content = @Content(schema = @Schema(implementation = MentorshipSlotResponse.class)))
    public ResponseEntity<MentorshipSlotResponse> closeSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.closeSlot(actor, slotId));
    }

    @PostMapping("/{slotId}/reopen")
    @Operation(summary = "Reopen mentorship series enrollment", description = "Host only; requires a future meeting and a vacancy.")
    public ResponseEntity<MentorshipSlotResponse> reopenSlot(
            @AuthenticationPrincipal SessionPrincipal actor, @PathVariable Long slotId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(slotService.reopenSlot(actor, slotId));
    }

    @PostMapping("/{slotId}/cancel")
    @Operation(summary = "Cancel a mentorship session", description = "Mentor can cancel the session and cancel all enrollments.")
    @ApiResponse(responseCode = "200", description = "Slot cancelled", content = @Content(schema = @Schema(implementation = MentorshipSlotResponse.class)))
    public ResponseEntity<MentorshipSlotResponse> cancelSlot(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.cancelSlot(actor, slotId));
    }

    @GetMapping("/my-mentoring")
    @Operation(summary = "List mentorship slots created by current mentor")
    @ApiResponse(responseCode = "200", description = "List of created mentorship slots")
    public ResponseEntity<List<MentorshipSlotResponse>> myMentoring(
            @AuthenticationPrincipal SessionPrincipal actor
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.getMyMentoringSlots(actor));
    }

    @GetMapping("/my-enrolled")
    @Operation(summary = "List mentorship slots joined by current mentee")
    @ApiResponse(responseCode = "200", description = "List of joined mentorship slots")
    public ResponseEntity<List<MentorshipEnrollmentResponse>> myEnrolled(
            @AuthenticationPrincipal SessionPrincipal actor
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.getMyEnrolledSlots(actor));
    }

    @GetMapping("/my-hosted-series")
    @Operation(summary = "List card-ready mentorship series hosted by the current mentor")
    public ResponseEntity<List<MentorshipSlotSummaryResponse>> myHostedSeries(
            @AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(slotService.getMyHostedSeries(actor));
    }

    @GetMapping("/my-current-series")
    @Operation(summary = "List card-ready current mentorship series joined by the current participant")
    public ResponseEntity<List<MentorshipSlotSummaryResponse>> myCurrentSeries(
            @AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.getMyCurrentSeries(actor));
    }

    @GetMapping("/my-participation")
    @Operation(summary = "List current and historical mentorship participation periods")
    public ResponseEntity<List<MentorshipEnrollmentResponse>> myParticipation(
            @AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(slotService.getMyParticipation(actor));
    }

    @GetMapping("/enrollments/{enrollmentId}")
    @Operation(summary = "View one enrollment", description = "Visible only to its mentee and the hosting mentor.")
    public ResponseEntity<MentorshipEnrollmentResponse> getEnrollment(
            @AuthenticationPrincipal SessionPrincipal actor, @PathVariable Long enrollmentId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(slotService.getEnrollment(actor, enrollmentId));
    }

    @GetMapping("/{slotId}/enrollments")
    @Operation(summary = "List enrolled attendees for a mentorship slot", description = "Only the mentor hosting the slot can view the enrolled mentees.")
    @ApiResponse(responseCode = "200", description = "List of enrolled attendees", content = @Content(schema = @Schema(implementation = MentorshipEnrollmentResponse.class)))
    public ResponseEntity<List<MentorshipEnrollmentResponse>> getEnrollments(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long slotId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(slotService.getSlotEnrollments(actor, slotId));
    }
}
