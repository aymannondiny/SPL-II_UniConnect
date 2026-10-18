package com.uniconnect.notification.service;

import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class AccountNotificationService {
    private final NotificationRepository notifications;
    public AccountNotificationService(NotificationRepository notifications) { this.notifications = notifications; }
    public void statusChanged(long recipient, long actionId, boolean restored, LocalDateTime now) {
        notifications.save(Notification.accountStatus(recipient, actionId, restored, now));
    }
}
