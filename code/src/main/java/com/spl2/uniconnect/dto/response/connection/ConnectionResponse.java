package com.spl2.uniconnect.dto.response.connection;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.spl2.uniconnect.domain.connection.ConnectionStatus;
import com.spl2.uniconnect.dto.response.user.UserResponse;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ConnectionResponse {

    private Long id;

    // The "other" user in the connection (from perspective of current user)
    private UserResponse connectedUser;

    // Who sent the connection request
    private UserResponse requester;

    private ConnectionStatus status;

    private String requestMessage;  // ✅ Optional message with request

    private LocalDateTime createdAt;
    private LocalDateTime acceptedAt;

    // ✅ Helper field: Did the current user send this request?
    private boolean isRequestedByCurrentUser;
}
