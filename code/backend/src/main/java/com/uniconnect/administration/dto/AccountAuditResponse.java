package com.uniconnect.administration.dto;

import com.uniconnect.administration.domain.*;
import com.uniconnect.shared.security.AccountStatus;
import java.time.LocalDateTime;

public record AccountAuditResponse(long auditId, long actionId, long actorId, long targetUserId,
        ModerationActionType actionType, AuditEventType eventType, String reason,
        AccountStatus previousState, AccountStatus newState, LocalDateTime occurredAt,
        LocalDateTime reversedAt, Long reversalOfActionId) {
    public static AccountAuditResponse from(AuditLog log) {
        var action = log.getModerationAction();
        return new AccountAuditResponse(log.getId(), action.getId(), log.getActorId(), log.getSubjectId(),
                action.getActionType(), log.getEventType(), log.getReason(), action.getPreviousState(),
                action.getNewState(), log.getOccurredAt(), action.getReversedAt(), action.getReversalOfActionId());
    }
}
