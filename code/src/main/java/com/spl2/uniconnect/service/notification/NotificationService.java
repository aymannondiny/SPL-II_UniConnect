package com.spl2.uniconnect.service.notification;

import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
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

    @Transactional(readOnly = true)
    public Page<Notification> getMyNotifications(Long userId, Pageable pageable) {
        return notificationRepository.findByUserUserId(userId, pageable);
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(Long userId) {
        return notificationRepository.countUnreadByUserId(userId);
    }

    public void markAsRead(Long notificationId, Long userId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));

        if (!notification.getUser().getUserId().equals(userId)) {
            throw new ForbiddenException("Not allowed");
        }

        notification.markAsRead();
        notificationRepository.save(notification);
    }

    public void markAllAsRead(Long userId) {
        notificationRepository.findUnreadByUserId(userId)
                .forEach(n -> n.setIsRead(true));
    }

    @Transactional(readOnly = true)
    public Notification getById(Long id, Long userId) {
        Notification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));

        if (!notification.getUser().getUserId().equals(userId)) {
            throw new ForbiddenException("Access denied");
        }

        return notification;
    }

    public void deleteNotification(Long id, Long userId) {
        Notification notification = getById(id, userId);
        notificationRepository.delete(notification);
    }

    public void deleteAllForUser(Long userId) {
        notificationRepository.deleteByUserUserId(userId);
    }

    @Transactional(readOnly = true)
    public Page<Notification> getByType(Long userId, NotificationType type, Pageable pageable) {
        return notificationRepository.findByUserUserIdAndType(userId, type, pageable);
    }
}