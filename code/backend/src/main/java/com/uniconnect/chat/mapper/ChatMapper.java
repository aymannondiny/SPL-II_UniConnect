package com.uniconnect.chat.mapper;
import com.uniconnect.chat.domain.*;
import com.uniconnect.chat.dto.MessageResponse;
import org.springframework.stereotype.Component;
@Component
public class ChatMapper {
    public MessageResponse message(ChatMessage m, MessageParticipantState recipient) {
        return new MessageResponse(m.getId(), m.getConversationId(), m.getSenderId(), m.getClientMessageId(),
                m.getDeletedForEveryoneAt() == null ? m.getContent() : null, m.getSentAt(),
                recipient.getDeliveredAt(), recipient.getReadAt(), m.getDeletedForEveryoneAt());
    }
}
