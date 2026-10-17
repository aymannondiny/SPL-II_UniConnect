package com.uniconnect.chat.dto;
import java.util.List;
public record HistoryResponse(Long conversationId, boolean canSend, List<MessageResponse> items,
        boolean hasMore, Long nextBeforeMessageId) {}
