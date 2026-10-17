package com.uniconnect.chat.domain;
import jakarta.persistence.*;
import java.time.LocalDateTime;
@Entity @Table(name="chat_message_states")
public class MessageParticipantState {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long stateId;
    @Column(nullable=false) private Long messageId;
    @Column(nullable=false) private Long conversationId;
    @Column(nullable=false) private Long userId;
    private LocalDateTime deliveredAt;
    private LocalDateTime readAt;
    private LocalDateTime deletedForSelfAt;
    protected MessageParticipantState() {}
    public MessageParticipantState(long message, long conversation, long user) {
        messageId=message; conversationId=conversation; userId=user;
    }
    public boolean delivered(LocalDateTime now) {
        if (deliveredAt != null) return false;
        deliveredAt=now; return true;
    }
    public boolean read(LocalDateTime now) {
        if (readAt != null) return false;
        delivered(now); readAt=now; return true;
    }
    public boolean deleteForSelf(LocalDateTime now) {
        if (deletedForSelfAt != null) return false;
        deletedForSelfAt=now; return true;
    }
    public LocalDateTime getDeliveredAt() { return deliveredAt; }
    public LocalDateTime getReadAt() { return readAt; }
    public LocalDateTime getDeletedForSelfAt() { return deletedForSelfAt; }
}
