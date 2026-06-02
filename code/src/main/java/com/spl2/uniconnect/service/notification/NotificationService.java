package com.spl2.uniconnect.service.notification;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.spl2.uniconnect.domain.notification.Notification;
import com.spl2.uniconnect.domain.notification.NotificationType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.repository.notification.NotificationRepository;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;

    /**
     * Send connection request notification
     */
    public void sendConnectionRequestNotification(User requester, User receiver) {
        String content = requester.getFullName() + " sent you a connection request";

        Notification notification = Notification.builder()
                .user(receiver)
                .type(NotificationType.CONNECTION_REQUEST)
                .content(content)
                .referenceId(requester.getUserId())
                .referenceType("USER")
                .isRead(false)
                .build();

        notificationRepository.save(notification);

        log.info("Connection request notification sent to user {}", receiver.getUserId());
    }

    /**
     * Send connection accepted notification
     */
    public void sendConnectionAcceptedNotification(User acceptor, User requester) {
        String content = acceptor.getFullName() + " accepted your connection request";

        Notification notification = Notification.builder()
                .user(requester)
                .type(NotificationType.CONNECTION_ACCEPTED)
                .content(content)
                .referenceId(acceptor.getUserId())
                .referenceType("USER")
                .isRead(false)
                .build();

        notificationRepository.save(notification);

        log.info("Connection accepted notification sent to user {}", requester.getUserId());
    }

    /**
     * Generic method to create notification
     */
    public void createNotification(
            User recipient,
            NotificationType type,
            String content,
            Long referenceId,
            String referenceType) {

        Notification notification = Notification.builder()
                .user(recipient)
                .type(type)
                .content(content)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .isRead(false)
                .build();

        notificationRepository.save(notification);

        log.info("Notification created for user {}: {}", recipient.getUserId(), type);
    }
}