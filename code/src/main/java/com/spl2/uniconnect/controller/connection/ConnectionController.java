package com.spl2.uniconnect.controller.connection;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;
import com.spl2.uniconnect.dto.request.connection.ConnectionRequest;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.connection.ConnectionResponse;
import com.spl2.uniconnect.dto.response.connection.ConnectionStatsResponse;
import com.spl2.uniconnect.service.connection.ConnectionService;

@RestController
@RequestMapping("/api/connections")
@RequiredArgsConstructor
@Tag(name = "Connections", description = "Connection/Friend request management APIs")
public class ConnectionController {

    private final ConnectionService connectionService;

    @PostMapping("/request")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Send connection request", description = "Send a connection request to another user")
    public ResponseEntity<ApiResponse<ConnectionResponse>> sendConnectionRequest(
            @Valid @RequestBody ConnectionRequest request) {

        ConnectionResponse response = connectionService.sendConnectionRequest(request);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("Connection request sent successfully", response));
    }

    @PutMapping("/{connectionId}/accept")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Accept connection request", description = "Accept a pending connection request")
    public ResponseEntity<ApiResponse<ConnectionResponse>> acceptConnectionRequest(
            @PathVariable Long connectionId) {

        ConnectionResponse response = connectionService.acceptConnectionRequest(connectionId);

        return ResponseEntity.ok(
                ApiResponse.success("Connection request accepted", response)
        );
    }

    @PutMapping("/{connectionId}/reject")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Reject connection request", description = "Reject a pending connection request")
    public ResponseEntity<ApiResponse<Void>> rejectConnectionRequest(
            @PathVariable Long connectionId) {

        connectionService.rejectConnectionRequest(connectionId);

        return ResponseEntity.ok(
                ApiResponse.success("Connection request rejected")
        );
    }

    @DeleteMapping("/{connectionId}/cancel")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Cancel sent request", description = "Cancel a connection request you sent")
    public ResponseEntity<ApiResponse<Void>> cancelConnectionRequest(
            @PathVariable Long connectionId) {

        connectionService.cancelConnectionRequest(connectionId);

        return ResponseEntity.ok(
                ApiResponse.success("Connection request cancelled")
        );
    }

    @DeleteMapping("/users/{userId}")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Remove connection", description = "Remove an existing connection")
    public ResponseEntity<ApiResponse<Void>> removeConnection(
            @PathVariable Long userId) {

        connectionService.removeConnection(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Connection removed successfully")
        );
    }

    @GetMapping("/my-connections")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Get my connections", description = "Get all accepted connections (friends)")
    public ResponseEntity<ApiResponse<Page<ConnectionResponse>>> getMyConnections(
            @PageableDefault(size = 20, sort = "acceptedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ConnectionResponse> connections = connectionService.getMyConnections(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Connections retrieved successfully", connections)
        );
    }

    @GetMapping("/requests/received")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Get pending requests received", description = "Get all pending connection requests you received")
    public ResponseEntity<ApiResponse<Page<ConnectionResponse>>> getPendingRequestsReceived(
            @PageableDefault(size = 20, sort = "requestedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ConnectionResponse> requests = connectionService.getPendingRequestsReceived(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Pending requests retrieved successfully", requests)
        );
    }

    @GetMapping("/requests/sent")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Get pending requests sent", description = "Get all pending connection requests you sent")
    public ResponseEntity<ApiResponse<Page<ConnectionResponse>>> getPendingRequestsSent(
            @PageableDefault(size = 20, sort = "requestedAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<ConnectionResponse> requests = connectionService.getPendingRequestsSent(pageable);

        return ResponseEntity.ok(
                ApiResponse.success("Sent requests retrieved successfully", requests)
        );
    }

    @GetMapping("/stats")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Get connection statistics", description = "Get connection counts and statistics")
    public ResponseEntity<ApiResponse<ConnectionStatsResponse>> getConnectionStats() {

        ConnectionStatsResponse stats = connectionService.getConnectionStats();

        return ResponseEntity.ok(
                ApiResponse.success("Statistics retrieved successfully", stats)
        );
    }

    @GetMapping("/status/{userId}")
    @PreAuthorize("hasAnyRole('STUDENT', 'ALUMNI', 'CLUB_ADMIN')")
    @Operation(summary = "Check connection status", description = "Check connection status with a specific user")
    public ResponseEntity<ApiResponse<ConnectionStatus>> getConnectionStatus(
            @PathVariable Long userId) {

        ConnectionStatus status = connectionService.getConnectionStatus(userId);

        return ResponseEntity.ok(
                ApiResponse.success("Connection status retrieved", status)
        );
    }
}