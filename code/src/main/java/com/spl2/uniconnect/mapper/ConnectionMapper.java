package com.spl2.uniconnect.mapper;

import com.spl2.uniconnect.domain.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import com.spl2.uniconnect.domain.connection.Connection;
import com.spl2.uniconnect.dto.response.connection.ConnectionResponse;
import com.spl2.uniconnect.dto.response.user.UserResponse;

@Component
@RequiredArgsConstructor
public class ConnectionMapper {

    private final UserMapper userMapper;

    /**
     * Convert Connection entity to ConnectionResponse
     * @param connection The connection entity
     * @param currentUserId The ID of the current user viewing the connection
     * @return ConnectionResponse with the "other" user highlighted
     */
    public ConnectionResponse toResponse(Connection connection, Long currentUserId) {
        // Get the "other" user (the one who is NOT the current user)
        User otherUser = connection.getOtherUser(currentUserId);
        User requester = connection.getRequestedBy();

        UserResponse otherUserResponse = userMapper.toUserResponse(otherUser);
        UserResponse requesterResponse = userMapper.toUserResponse(requester);

        return ConnectionResponse.builder()
                .id(connection.getConnectionId())
                .connectedUser(otherUserResponse)  // The person on the other end
                .requester(requesterResponse)      // Who sent the request
                .status(connection.getStatus())
                .requestMessage(connection.getRequestMessage())
                .createdAt(connection.getRequestedAt())
                .acceptedAt(connection.getAcceptedAt())
                .isRequestedByCurrentUser(connection.isRequestedBy(currentUserId))
                .build();
    }
}