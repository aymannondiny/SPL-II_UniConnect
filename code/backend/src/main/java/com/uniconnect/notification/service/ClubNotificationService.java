package com.uniconnect.notification.service;
import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ClubNotificationService {
    private final NotificationRepository notifications;
    private final Clock clock;
    public ClubNotificationService(NotificationRepository notifications, Clock clock) { this.notifications = notifications; this.clock = clock; }
    public void publishingChanged(long recipient, long club, long auditId, boolean restored) {
        notifications.save(Notification.clubPublishing(recipient, club, auditId, restored, LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC)));
    }
    public void roleChanged(long recipient, long club, long assignment, String role, boolean granted) {
        notifications.save(Notification.clubRole(recipient, club, assignment, role, granted, LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC)));
    }
}
