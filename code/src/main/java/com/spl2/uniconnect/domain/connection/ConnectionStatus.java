package com.spl2.uniconnect.domain.connection;

import lombok.Getter;

@Getter
public enum ConnectionStatus {
    PENDING("Pending"),
    ACCEPTED("Accepted"),
    REJECTED("Rejected");  // ✅ ADDED: Useful for tracking declined requests

    private final String displayName;

    ConnectionStatus(String displayName) {
        this.displayName = displayName;
    }
}