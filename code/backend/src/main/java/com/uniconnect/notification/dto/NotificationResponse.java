package com.uniconnect.notification.dto;
import com.uniconnect.notification.domain.*;
import java.time.LocalDateTime;
public record NotificationResponse(Long id, NotificationType type, String title, String message,
        String referenceType, Long referenceId, LocalDateTime createdAt, LocalDateTime readAt) {
    public static NotificationResponse from(Notification n) {
        return new NotificationResponse(n.getId(), n.getType(), n.getTitle(), n.getMessage(),
                n.getReferenceType(), n.getReferenceId(), n.getCreatedAt(), n.getReadAt());
    }
}
