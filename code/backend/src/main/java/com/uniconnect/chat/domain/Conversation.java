package com.uniconnect.chat.domain;
import jakarta.persistence.*;
import java.time.LocalDateTime;
@Entity @Table(name="chat_conversations")
public class Conversation {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long conversationId;
    @Column(nullable=false, updatable=false) private Long userLow;
    @Column(nullable=false, updatable=false) private Long userHigh;
    @Column(nullable=false) private LocalDateTime createdAt;
    @Column(nullable=false) private LocalDateTime lastMessageAt;
    protected Conversation() {}
    public Conversation(long a, long b, LocalDateTime now) {
        if (a == b) throw new IllegalArgumentException("Distinct participants required");
        userLow=Math.min(a,b); userHigh=Math.max(a,b); createdAt=now; lastMessageAt=now;
    }
    public boolean includes(long user) { return userLow == user || userHigh == user; }
    public long other(long user) {
        if (!includes(user)) throw new IllegalArgumentException("Not a participant");
        return userLow == user ? userHigh : userLow;
    }
    public void messageSent(LocalDateTime now) { lastMessageAt=now; }
    public Long getId() { return conversationId; }
    public Long getUserLow() { return userLow; }
    public Long getUserHigh() { return userHigh; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getLastMessageAt() { return lastMessageAt; }
}
