package com.uniconnect.connection.service;

import com.uniconnect.connection.repository.ConnectionRepository;
import com.uniconnect.connection.dto.ConnectionSummary;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Internal relationship boundary; callers own authentication and the response's privacy policy. */
@Service
@Transactional(propagation = Propagation.MANDATORY, readOnly = true)
public class ConnectionQueryService {
    private final ConnectionRepository connections;
    public ConnectionQueryService(ConnectionRepository connections) { this.connections = connections; }
    public List<Long> acceptedPeers(long userId) { return connections.acceptedPeers(userId); }
    public Map<Long, ConnectionSummary> relationships(long userId) {
        Map<Long, ConnectionSummary> result = new HashMap<>();
        for (var c : connections.openForUser(userId)) {
            boolean outgoing = c.getRequesterId() == userId;
            long other = outgoing ? c.getReceiverId() : c.getRequesterId();
            result.put(other, new ConnectionSummary(c.getId(), c.getStatus(), outgoing));
        }
        return result;
    }
    public boolean areAccepted(long first, long second) {
        return connections.findByOpenLowAndOpenHigh(Math.min(first, second), Math.max(first, second))
                .filter(c -> c.getStatus() == com.uniconnect.connection.domain.ConnectionStatus.ACCEPTED).isPresent();
    }
}
