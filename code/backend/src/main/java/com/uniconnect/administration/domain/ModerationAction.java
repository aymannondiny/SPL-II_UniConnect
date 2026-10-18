package com.uniconnect.administration.domain;

import com.uniconnect.shared.security.AccountStatus;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "moderation_actions")
public class ModerationAction {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long actionId;
    @Column(nullable = false, updatable = false) private Long actorId;
    @Column(nullable = false, updatable = false) private Long targetUserId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 40, updatable = false)
    private ModerationActionType actionType;
    @Column(nullable = false, length = 1000, updatable = false) private String reason;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 50, updatable = false)
    private AccountStatus previousState;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 50, updatable = false)
    private AccountStatus newState;
    @Column(updatable = false) private Long reversalOfActionId;
    @Column(nullable = false, updatable = false) private LocalDateTime createdAt;
    private LocalDateTime reversedAt;

    protected ModerationAction() {}

    public ModerationAction(long actorId, long targetUserId, ModerationActionType actionType,
            String reason, AccountStatus previousState, AccountStatus newState,
            Long reversalOfActionId, LocalDateTime createdAt) {
        this.actorId = actorId;
        this.targetUserId = targetUserId;
        this.actionType = actionType;
        this.reason = reason;
        this.previousState = previousState;
        this.newState = newState;
        this.reversalOfActionId = reversalOfActionId;
        this.createdAt = createdAt;
    }

    public void markReversed(LocalDateTime now) {
        if (reversedAt == null) reversedAt = now;
    }

    public Long getId() { return actionId; }
    public Long getActorId() { return actorId; }
    public Long getTargetUserId() { return targetUserId; }
    public ModerationActionType getActionType() { return actionType; }
    public String getReason() { return reason; }
    public AccountStatus getPreviousState() { return previousState; }
    public AccountStatus getNewState() { return newState; }
    public Long getReversalOfActionId() { return reversalOfActionId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getReversedAt() { return reversedAt; }
}
