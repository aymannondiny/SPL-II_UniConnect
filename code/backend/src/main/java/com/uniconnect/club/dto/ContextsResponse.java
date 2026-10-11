package com.uniconnect.club.dto;
import java.time.LocalDateTime;
import java.util.List;
public record ContextsResponse(ContextResponse activeContext, LocalDateTime selectedAt, List<ContextResponse> availableContexts) {}
