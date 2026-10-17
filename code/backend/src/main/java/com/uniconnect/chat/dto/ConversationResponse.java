package com.uniconnect.chat.dto;
import java.time.LocalDateTime;
public record ConversationResponse(Long id, Long otherUserId, String otherFullName, boolean canSend,
        LocalDateTime createdAt, LocalDateTime lastMessageAt, MessageResponse latestVisibleMessage, long unreadCount) {}
