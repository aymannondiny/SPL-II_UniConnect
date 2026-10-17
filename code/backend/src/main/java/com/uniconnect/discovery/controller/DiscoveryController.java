package com.uniconnect.discovery.controller;
import com.uniconnect.discovery.service.DiscoveryService;
import com.uniconnect.profile.dto.*;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.PlatformRole;
import java.util.List;

import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/members")
@Tag(name = "Member discovery")

@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting connection state", content = @Content(schema = @Schema(implementation = ApiError.class)))

public class DiscoveryController {
    private final DiscoveryService discovery;
    public DiscoveryController(DiscoveryService discovery) { this.discovery = discovery; }
    @GetMapping
    @Operation(summary = "Find members using fields you may view", description = "Basic profiles are discoverable by ACTIVE members. Detail filters match only ALL_MEMBERS profiles or accepted connections. Skills require all supplied skills. Self is excluded. Sorting: NAME_ASC or NAME_DESC; page starts at 0; size is 1–50.")
    @ApiResponse(responseCode = "200", description = "Permitted member results")
    public ResponseEntity<PageResponse<MemberProfileResponse>> search(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) String name, @RequestParam(required = false) PlatformRole role,
            @RequestParam(required = false) Long departmentId, @RequestParam(required = false) Long programmeId,
            @RequestParam(required = false) List<String> skills, @RequestParam(required = false) Integer yearOfStudy,
            @RequestParam(required = false) Boolean projectAvailable, @RequestParam(required = false) Boolean mentorshipAvailable,
            @RequestParam(required = false) String company, @RequestParam(required = false) String industry,
            @RequestParam(required = false) Integer graduationYear, @RequestParam(defaultValue = "NAME_ASC") String sort,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(discovery.search(actor,
                new MemberSearch(name, role, departmentId, programmeId, skills, yearOfStudy, projectAvailable,
                        mentorshipAvailable, company, industry, graduationYear, sort, page, size)));
    }
    @GetMapping("/{userId}")
    @Operation(summary = "View a member's basic profile and permitted details")
    @ApiResponse(responseCode = "200", description = "Permitted profile", content = @Content(schema = @Schema(implementation = MemberProfileResponse.class)))
    public ResponseEntity<MemberProfileResponse> view(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long userId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(discovery.view(actor, userId));
    }
}
