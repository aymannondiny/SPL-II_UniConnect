package com.uniconnect.connection.dto;
import com.uniconnect.connection.domain.*;
import java.time.LocalDateTime;
public record ConnectionResponse(Long id, Long requesterId, Long receiverId, ConnectionStatus status,
        String introductoryMessage, LocalDateTime requestedAt, LocalDateTime acceptedAt, LocalDateTime closedAt) {
    public static ConnectionResponse from(Connection c) {
        return new ConnectionResponse(c.getId(), c.getRequesterId(), c.getReceiverId(), c.getStatus(),
                c.getIntroductoryMessage(), c.getRequestedAt(), c.getAcceptedAt(), c.getClosedAt());
    }
}
