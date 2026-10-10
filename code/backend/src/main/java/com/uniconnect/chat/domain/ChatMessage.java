package com.uniconnect.chat.domain;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;
@Entity @Table(name="chat_messages")
public class ChatMessage {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long messageId;
    @Column(nullable=false, updatable=false) private Long conversationId;
    @Column(nullable=false, updatable=false) private Long senderId;
    @Column(nullable=false, updatable=false) private UUID clientMessageId;
    @Column(nullable=false, length=5000, updatable=false) private String content;
    @Column(nullable=false, updatable=false) private LocalDateTime sentAt;
    private LocalDateTime deletedForEveryoneAt;
    protected ChatMessage() {}
    public ChatMessage(long conversation, long sender, UUID clientId, String content, LocalDateTime now) {
        conversationId=conversation; senderId=sender; clientMessageId=clientId; this.content=content; sentAt=now;
    }
    public boolean deleteForEveryone(LocalDateTime now) {
        if (deletedForEveryoneAt != null) return false;
        deletedForEveryoneAt=now; return true;
    }
    public Long getId() { return messageId; }
    public Long getConversationId() { return conversationId; }
    public Long getSenderId() { return senderId; }
    public UUID getClientMessageId() { return clientMessageId; }
    public String getContent() { return content; }
    public LocalDateTime getSentAt() { return sentAt; }
    public LocalDateTime getDeletedForEveryoneAt() { return deletedForEveryoneAt; }
}
