package com.uniconnect.connection.dto;
import com.uniconnect.connection.domain.ConnectionStatus;
public record ConnectionSummary(Long id, ConnectionStatus status, boolean outgoing) {}
