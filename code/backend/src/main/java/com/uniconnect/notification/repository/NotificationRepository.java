package com.uniconnect.notification.repository;
import com.uniconnect.notification.domain.Notification;
import java.util.Optional;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    Page<Notification> findByRecipientIdAndDismissedAtIsNull(long recipientId, Pageable page);
    Optional<Notification> findByNotificationIdAndRecipientId(long id, long recipientId);
}
