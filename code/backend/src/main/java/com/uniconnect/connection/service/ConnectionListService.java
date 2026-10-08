package com.uniconnect.connection.service;

import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.connection.domain.ConnectionStatus;
import com.uniconnect.connection.dto.ConnectionListItem;
import com.uniconnect.connection.repository.ConnectionListRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.BadRequestException;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ConnectionListService {
    private final ProfileAccountService accounts;
    private final ConnectionListRepository connections;
    public ConnectionListService(ProfileAccountService accounts, ConnectionListRepository connections) {
        this.accounts = accounts;
        this.connections = connections;
    }
    public PageResponse<ConnectionListItem> list(SessionPrincipal actor, ConnectionStatus status, String direction,
            String name, String sort, int page, int size) {
        accounts.lockActiveAccount(actor);
        PageValidation.check(page, size);
        if (direction == null || sort == null || !Set.of("ALL", "INCOMING", "OUTGOING").contains(direction)
                || !Set.of("NEWEST", "NAME").contains(sort) || status == null || (name != null && name.length() > 100))
            throw new BadRequestException("INVALID_CONNECTION_FILTER", "Invalid connection filters or sort.");
        return connections.list(actor, status, direction, name, sort, page, size);
    }
}
