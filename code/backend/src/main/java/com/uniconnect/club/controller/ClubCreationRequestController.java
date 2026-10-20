package com.uniconnect.club.controller;

import com.uniconnect.club.domain.ClubCreationRequestStatus;
import com.uniconnect.club.dto.*;
import com.uniconnect.club.service.ClubCreationRequestService;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/club-requests")
@Tag(name = "Club creation requests")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid club request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Student role or administrator context required", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class ClubCreationRequestController {
    private final ClubCreationRequestService requests;
    public ClubCreationRequestController(ClubCreationRequestService requests) { this.requests = requests; }

    @PostMapping
    @Operation(summary = "Submit a student club creation request")
    public ResponseEntity<ClubCreationRequestResponse> submit(@AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody ClubCreationRequestSubmission body) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(requests.submit(actor, body));
    }
    @GetMapping("/mine")
    @Operation(summary = "List the current student's club requests")
    public ResponseEntity<List<ClubCreationRequestResponse>> mine(@AuthenticationPrincipal SessionPrincipal actor) {
        return ok(requests.mine(actor));
    }
    private <T> ResponseEntity<T> ok(T value) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(value); }
}
