package com.uniconnect.notification.service;

import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ProjectNotificationService {
    private final NotificationRepository notifications;
    public ProjectNotificationService(NotificationRepository notifications) { this.notifications = notifications; }
    public void applicationReviewed(long recipient, long project, long application, boolean accepted, LocalDateTime now) {
        notifications.save(Notification.projectApplication(recipient, project, application, accepted, now));
    }
    public void projectDeleted(long recipient, long project, long application, LocalDateTime now) {
        notifications.save(Notification.projectDeleted(recipient, project, application, now));
    }
}
