package com.uniconnect.chat.dto;
import java.time.LocalDateTime;
import java.util.UUID;
public record MessageResponse(Long id, Long conversationId, Long senderId, UUID clientMessageId,
        String content, LocalDateTime sentAt, LocalDateTime deliveredAt, LocalDateTime readAt,
        LocalDateTime deletedForEveryoneAt) {}
