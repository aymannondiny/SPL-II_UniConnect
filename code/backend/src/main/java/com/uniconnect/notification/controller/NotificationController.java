package com.uniconnect.notification.controller;
import com.uniconnect.notification.dto.NotificationResponse;
import com.uniconnect.notification.service.NotificationService;
import com.uniconnect.shared.dto.PageResponse;

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
@RequestMapping("/api/v1/notifications")
@Tag(name = "Connection notifications")

@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting connection state", content = @Content(schema = @Schema(implementation = ApiError.class)))

public class NotificationController {
    private final NotificationService notifications;
    public NotificationController(NotificationService notifications) { this.notifications = notifications; }
    @GetMapping
    @Operation(summary = "List your notifications", description = "A reference never grants access: fetch the connection endpoint to recheck current authorization.")
    @ApiResponse(responseCode = "200", description = "Your notifications")
    public ResponseEntity<PageResponse<NotificationResponse>> list(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(notifications.list(actor, page, size));
    }
    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark your notification as read")
    @ApiResponse(responseCode = "200", description = "Read notification", content = @Content(schema = @Schema(implementation = NotificationResponse.class)))
    public ResponseEntity<NotificationResponse> read(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(notifications.read(actor, id));
    }
}
