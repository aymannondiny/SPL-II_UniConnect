package com.uniconnect.administration.controller;

import com.uniconnect.administration.dto.*;
import com.uniconnect.administration.service.AccountModerationService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ApiError;
import com.uniconnect.shared.security.*;
import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/accounts")
@Tag(name = "Account administration")
@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Administration access denied", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Account unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Invalid or concurrently changed account state", content = @Content(schema = @Schema(implementation = ApiError.class)))
public class AccountAdministrationController {
    private final AccountModerationService accounts;
    public AccountAdministrationController(AccountModerationService accounts) { this.accounts = accounts; }

    @GetMapping
    @Operation(summary = "Search registered accounts", description = "Requires selected SYSTEM_ADMINISTRATION context.")
    public ResponseEntity<PageResponse<AccountResponse>> search(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "") String search,
            @RequestParam(required = false) PlatformRole role,
            @RequestParam(required = false) AccountStatus status,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ok(accounts.search(actor, search, role, status, page, size));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Read account administration details")
    public ResponseEntity<AccountResponse> get(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) {
        return ok(accounts.get(actor, id));
    }

    @PostMapping("/{id}/suspend")
    @Operation(summary = "Suspend an ACTIVE student or alumni account",
            description = "Revokes all sessions and suspends publishing for clubs currently administered by the account.")
    public ResponseEntity<AccountResponse> suspend(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody AccountModerationRequest request) {
        return ok(accounts.suspend(actor, id, request));
    }

    @PostMapping("/{id}/restore")
    @Operation(summary = "Restore a SUSPENDED student or alumni account",
            description = "Old sessions stay revoked. Club publishing remains suspended until explicitly restored.")
    public ResponseEntity<AccountResponse> restore(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id,
            @Valid @RequestBody AccountModerationRequest request) {
        return ok(accounts.restore(actor, id, request));
    }

    @GetMapping("/{id}/audit")
    @Operation(summary = "Read retained account moderation audit history")
    public ResponseEntity<PageResponse<AccountAuditResponse>> audit(@AuthenticationPrincipal SessionPrincipal actor,
            @PathVariable long id, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ok(accounts.audit(actor, id, page, size));
    }

    private <T> ResponseEntity<T> ok(T body) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body);
    }
}
