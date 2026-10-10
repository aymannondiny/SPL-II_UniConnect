package com.uniconnect.chat.domain;
import jakarta.persistence.*;
import java.time.LocalDateTime;
@Entity @Table(name="chat_participants")
public class ConversationParticipant {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long participantId;
    @Column(nullable=false) private Long conversationId;
    @Column(nullable=false) private Long userId;
    @Column(nullable=false) private Integer slot;
    @Column(nullable=false) private LocalDateTime joinedAt;
    protected ConversationParticipant() {}
    public ConversationParticipant(long conversation, long user, int slot, LocalDateTime now) {
        conversationId=conversation; userId=user; this.slot=slot; joinedAt=now;
    }
}
