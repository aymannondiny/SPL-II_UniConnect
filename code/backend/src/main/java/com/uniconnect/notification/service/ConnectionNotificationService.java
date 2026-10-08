package com.uniconnect.notification.service;
import com.uniconnect.notification.domain.*;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;

/** Writes join the connection transaction; rollback also removes the notification. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class ConnectionNotificationService {
    private final NotificationRepository notifications;
    private final Clock clock;
    public ConnectionNotificationService(NotificationRepository notifications, Clock clock) {
        this.notifications = notifications;
        this.clock = clock;
    }
    public void requested(long recipient, long connection) { save(recipient, connection, NotificationType.CONNECTION_REQUESTED); }
    public void accepted(long recipient, long connection) { save(recipient, connection, NotificationType.CONNECTION_ACCEPTED); }
    private void save(long recipient, long connection, NotificationType type) {
        notifications.save(new Notification(recipient, connection, type, LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC)));
    }
}
