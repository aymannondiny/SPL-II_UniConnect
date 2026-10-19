package com.uniconnect.notification.service;

import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ChatNotificationService {
    private final NotificationRepository notifications;

    public ChatNotificationService(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public void messageReceived(long recipient, long conversation, long messageId, String senderName, LocalDateTime sentAt) {
        notifications.save(Notification.newMessage(recipient, conversation, messageId, senderName, sentAt));
    }
}
