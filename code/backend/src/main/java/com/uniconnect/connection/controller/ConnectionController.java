package com.uniconnect.connection.controller;
import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.dto.*;
import com.uniconnect.connection.service.*;
import com.uniconnect.shared.dto.PageResponse;
import jakarta.validation.Valid;

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
@RequestMapping("/api/v1/connections")
@Tag(name = "Connections")

@SecurityRequirement(name = "sessionBearer")
@ApiResponse(responseCode = "400", description = "Invalid request", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "401", description = "Invalid or missing session", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "403", description = "Action not permitted", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "404", description = "Resource unavailable", content = @Content(schema = @Schema(implementation = ApiError.class)))
@ApiResponse(responseCode = "409", description = "Conflicting connection state", content = @Content(schema = @Schema(implementation = ApiError.class)))

public class ConnectionController {
    private final ConnectionService connections;
    private final ConnectionListService lists;
    public ConnectionController(ConnectionService connections, ConnectionListService lists) { this.connections = connections; this.lists = lists; }
    @PostMapping
    @Operation(summary = "Send a connection request with an optional introduction")
    @ApiResponse(responseCode = "201", description = "Request created", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> send(@AuthenticationPrincipal SessionPrincipal actor, @Valid @RequestBody ConnectionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).cacheControl(CacheControl.noStore()).body(connections.send(actor, request));
    }
    @GetMapping
    @Operation(summary = "List your connections or requests", description = "Default: ACCEPTED, all directions, newest first. totalElements is derived from the selected filters. INCOMING/OUTGOING refer to original request direction.")
    @ApiResponse(responseCode = "200", description = "Paginated connections")
    public ResponseEntity<PageResponse<ConnectionListItem>> list(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue = "ACCEPTED") ConnectionStatus status,
            @RequestParam(defaultValue = "ALL") String direction, @RequestParam(required = false) String name,
            @RequestParam(defaultValue = "NEWEST") String sort, @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(lists.list(actor, status, direction, name, sort, page, size));
    }
    @GetMapping("/{id}")
    @Operation(summary = "Read a connection record you participate in")
    @ApiResponse(responseCode = "200", description = "Connection record", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> get(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return response(connections.get(actor, id)); }

    @PostMapping("/{id}/accept")
    @Operation(summary = "Accept a connection")
    @ApiResponse(responseCode = "200", description = "Updated connection", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> accept(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return response(connections.accept(actor, id)); }

    @PostMapping("/{id}/reject")
    @Operation(summary = "Reject a connection")
    @ApiResponse(responseCode = "200", description = "Updated connection", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> reject(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return response(connections.reject(actor, id)); }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel a connection")
    @ApiResponse(responseCode = "200", description = "Updated connection", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> cancel(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return response(connections.cancel(actor, id)); }

    @PostMapping("/{id}/remove")
    @Operation(summary = "Remove a connection")
    @ApiResponse(responseCode = "200", description = "Updated connection", content = @Content(schema = @Schema(implementation = ConnectionResponse.class)))
    public ResponseEntity<ConnectionResponse> remove(@AuthenticationPrincipal SessionPrincipal actor, @PathVariable long id) { return response(connections.remove(actor, id)); }

    private ResponseEntity<ConnectionResponse> response(ConnectionResponse result) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(result); }
}
