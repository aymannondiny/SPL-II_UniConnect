package com.spl2.uniconnect.mapper;

import org.springframework.stereotype.Component;
import com.spl2.uniconnect.domain.notification.Notification;
import com.spl2.uniconnect.dto.response.notification.NotificationResponse;

@Component
public class NotificationMapper {

    public NotificationResponse toResponse(Notification notification) {
        return NotificationResponse.builder()
                .id(notification.getNotificationId())
                .type(notification.getType().name())
                .content(notification.getContent())
                .referenceId(notification.getReferenceId())
                .referenceType(notification.getReferenceType())
                .isRead(notification.getIsRead())
                .createdAt(notification.getCreatedAt())
                .build();
    }
}