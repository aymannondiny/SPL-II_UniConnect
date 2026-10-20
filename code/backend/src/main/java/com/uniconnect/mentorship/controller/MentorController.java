package com.uniconnect.mentorship.controller;

import com.uniconnect.mentorship.dto.*;
import com.uniconnect.mentorship.service.PeerMentorService;
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

@RestController
@RequestMapping("/api/v1/mentorship/mentors")
@Tag(name = "Peer Mentorship")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting mentorship state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class MentorController {

    private final PeerMentorService mentorService;

    public MentorController(PeerMentorService mentorService) {
        this.mentorService = mentorService;
    }

    @PostMapping
    @Operation(summary = "Register as a peer mentor", description = "Eligible students (year 2+) and alumni can register with bio and expertise.")
    @ApiResponse(responseCode = "201", description = "Mentor registered", content = @Content(schema = @Schema(implementation = MentorProfileResponse.class)))
    public ResponseEntity<MentorProfileResponse> register(
            @AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody MentorRegistrationRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .cacheControl(CacheControl.noStore())
                .body(mentorService.registerMentor(actor, request));
    }

    @GetMapping("/me")
    @Operation(summary = "Get your own mentor profile")
    @ApiResponse(responseCode = "200", description = "Own mentor profile", content = @Content(schema = @Schema(implementation = MentorProfileResponse.class)))
    public ResponseEntity<MentorProfileResponse> myProfile(@AuthenticationPrincipal SessionPrincipal actor) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(mentorService.myProfile(actor));
    }

    @PatchMapping("/me/status")
    @Operation(summary = "Update mentor availability status")
    @ApiResponse(responseCode = "200", description = "Updated mentor profile", content = @Content(schema = @Schema(implementation = MentorProfileResponse.class)))
    public ResponseEntity<MentorProfileResponse> updateStatus(
            @AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody MentorStatusUpdateRequest request
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(mentorService.updateStatus(actor, request));
    }

    @GetMapping
    @Operation(summary = "Browse or search available mentors in the directory")
    @ApiResponse(responseCode = "200", description = "Paginated list of available mentors")
    public ResponseEntity<PageResponse<MentorSummaryResponse>> search(
            @AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) String topic,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) Integer yearOfStudy,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(mentorService.searchMentors(actor, topic, departmentId, yearOfStudy, page, size));
    }

    @GetMapping("/{mentorProfileId}")
    @Operation(summary = "View a mentor profile by ID")
    @ApiResponse(responseCode = "200", description = "Mentor profile details", content = @Content(schema = @Schema(implementation = MentorProfileResponse.class)))
    public ResponseEntity<MentorProfileResponse> getMentor(
            @AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable Long mentorProfileId
    ) {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(mentorService.getMentorProfile(actor, mentorProfileId));
    }
}
