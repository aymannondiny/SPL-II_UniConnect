package com.uniconnect.career.controller;

import com.uniconnect.career.domain.ApplicationChannel;
import com.uniconnect.career.domain.CareerSort;
import com.uniconnect.career.domain.EmploymentType;
import com.uniconnect.career.domain.WorkMode;
import com.uniconnect.career.dto.CareerPostRequest;
import com.uniconnect.career.dto.CareerPostResponse;
import com.uniconnect.career.dto.SaveJobRequest;
import com.uniconnect.career.dto.SavedJobResponse;
import com.uniconnect.career.dto.UpdateSavedNoteRequest;
import com.uniconnect.career.service.CareerBoardService;
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
import java.net.URI;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/career")
@Tag(name = "Career Board")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid career request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Required student or alumni authority is absent", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Post or bookmark is unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Post or bookmark state conflicts with the operation", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class CareerBoardController {
    private final CareerBoardService career;

    public CareerBoardController(CareerBoardService career) { this.career = career; }

    @PostMapping("/posts")
    @Operation(summary = "Publish a career post", description = "Requires an ACTIVE ALUMNI account. Dates use Asia/Dhaka; timestamps are UTC.")
    @ApiResponse(responseCode = "201", description = "Post published", content = @Content(schema = @Schema(implementation = CareerPostResponse.class)))
    public ResponseEntity<CareerPostResponse> create(@AuthenticationPrincipal SessionPrincipal actor,
            @Valid @RequestBody CareerPostRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore())
                .body(career.create(actor, request));
    }

    @GetMapping("/posts")
    @Operation(summary = "Browse active career posts", description = "ACTIVE STUDENT or ALUMNI. Filters combine with AND. Active means PUBLISHED, not author-redacted, and applicationDeadline is today or later in Asia/Dhaka. page 0–100000; size 1–50.")
    @ApiResponse(responseCode = "200", description = "Active career posts")
    public ResponseEntity<PageResponse<CareerPostResponse>> browse(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(required = false) EmploymentType employmentType,
            @RequestParam(required = false) String location,
            @RequestParam(required = false) WorkMode workMode,
            @RequestParam(required = false) String skill,
            @RequestParam(defaultValue = "POSTED_AT_DESC") CareerSort sort,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ok(career.browse(actor, employmentType, location, workMode, skill, sort, page, size));
    }

    @GetMapping("/posts/mine")
    @Operation(summary = "List my authored career posts", description = "ACTIVE ALUMNI authors receive published, derived-expired and closed posts.")
    @ApiResponse(responseCode = "200", description = "Authored career posts")
    public ResponseEntity<PageResponse<CareerPostResponse>> mine(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(career.mine(actor, page, size));
    }

    @GetMapping("/posts/{postId}")
    @Operation(summary = "View career post details", description = "Students may view active posts and their own saved closed/expired posts. Authors may view their own non-removed posts.")
    @ApiResponse(responseCode = "200", description = "Career post details", content = @Content(schema = @Schema(implementation = CareerPostResponse.class)))
    public ResponseEntity<CareerPostResponse> detail(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long postId) {
        return ok(career.detail(actor, postId));
    }

    @PutMapping("/posts/{postId}")
    @Operation(summary = "Edit my career post", description = "Only the ACTIVE ALUMNI author may edit a PUBLISHED, non-expired post.")
    @ApiResponse(responseCode = "200", description = "Post updated", content = @Content(schema = @Schema(implementation = CareerPostResponse.class)))
    public ResponseEntity<CareerPostResponse> update(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long postId, @Valid @RequestBody CareerPostRequest request) {
        return ok(career.update(actor, postId, request));
    }

    @PostMapping("/posts/{postId}/close")
    @Operation(summary = "Permanently close my career post", description = "Closing is permanent. An identical retry returns the already-closed post; reopening and author deletion are unavailable.")
    @ApiResponse(responseCode = "200", description = "Post closed", content = @Content(schema = @Schema(implementation = CareerPostResponse.class)))
    public ResponseEntity<CareerPostResponse> close(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long postId) {
        return ok(career.close(actor, postId));
    }

    @PostMapping("/posts/{postId}/save")
    @Operation(summary = "Save an active career post", description = "ACTIVE STUDENT only. A student may have one bookmark per post.")
    @ApiResponse(responseCode = "201", description = "Post saved", content = @Content(schema = @Schema(implementation = SavedJobResponse.class)))
    public ResponseEntity<SavedJobResponse> save(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long postId, @Valid @RequestBody(required = false) SaveJobRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore())
                .body(career.save(actor, postId, request));
    }

    @DeleteMapping("/posts/{postId}/save")
    @Operation(summary = "Remove a saved career post", description = "Deletes only the current student's bookmark; the post is unchanged.")
    @ApiResponse(responseCode = "204", description = "Bookmark removed", content = @Content)
    public ResponseEntity<Void> unsave(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long postId) {
        career.unsave(actor, postId);
        return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
    }

    @GetMapping("/saved")
    @Operation(summary = "List my saved career posts", description = "Closed and derived-expired posts remain visible with applying disabled. Removed content is returned only as a redacted tombstone.")
    @ApiResponse(responseCode = "200", description = "Saved career posts")
    public ResponseEntity<PageResponse<SavedJobResponse>> saved(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(career.saved(actor, page, size));
    }

    @PatchMapping("/saved/{savedJobId}")
    @Operation(summary = "Update a saved-job note", description = "Only the bookmark owner may update its optional note.")
    @ApiResponse(responseCode = "200", description = "Saved note updated", content = @Content(schema = @Schema(implementation = SavedJobResponse.class)))
    public ResponseEntity<SavedJobResponse> updateNote(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long savedJobId, @Valid @RequestBody UpdateSavedNoteRequest request) {
        return ok(career.updateSavedNote(actor, savedJobId, request));
    }

    @GetMapping("/posts/{postId}/apply")
    @Operation(summary = "Open an external application channel", description = "ACTIVE STUDENT only. Revalidates current post activity, then redirects to the stored HTTPS URL or mailto URI. No internal application is created.")
    @ApiResponse(responseCode = "302", description = "External application redirect", content = @Content)
    public ResponseEntity<Void> apply(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long postId,
            @RequestParam(required = false) ApplicationChannel channel) {
        URI target = career.application(actor, postId, channel);
        return ResponseEntity.status(HttpStatus.FOUND).header(HttpHeaders.LOCATION, target.toString())
                .cacheControl(CacheControl.noStore()).build();
    }

    private <T> ResponseEntity<T> ok(T value) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(value);
    }
}
