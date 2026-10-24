package com.uniconnect.notification.service;

import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collection;

@Service
@Transactional(propagation = Propagation.MANDATORY)
public class MentorshipNotificationService {

    private final NotificationRepository notifications;

    public MentorshipNotificationService(NotificationRepository notifications) {
        this.notifications = notifications;
    }

    public void slotJoined(long mentorUserId, long menteeUserId, long slotId, long enrollmentId, String menteeName, String topic, LocalDateTime now) {
        notifications.save(Notification.mentorshipSlotJoined(mentorUserId, slotId, enrollmentId, menteeName, topic, true, now));
        notifications.save(Notification.mentorshipSlotJoined(menteeUserId, slotId, enrollmentId, menteeName, topic, false, now));
    }

    public void slotLeft(long mentorUserId, long slotId, long enrollmentId, String menteeName, String topic, LocalDateTime now) {
        notifications.save(Notification.mentorshipSlotLeft(mentorUserId, slotId, enrollmentId, menteeName, topic, now));
    }

    public void slotCancelled(Collection<Long> menteeUserIds, long slotId, String topic, LocalDateTime now) {
        if (menteeUserIds == null || menteeUserIds.isEmpty()) return;
        for (Long menteeId : menteeUserIds) {
            notifications.save(Notification.mentorshipSlotCancelled(menteeId, slotId, topic, now));
        }
    }

    public void slotUpdated(
            Collection<Long> menteeUserIds,
            long slotId,
            String topic,
            String editId,
            LocalDateTime now) {
        if (menteeUserIds == null || menteeUserIds.isEmpty()) return;
        for (Long menteeId : menteeUserIds) {
            notifications.save(Notification.mentorshipSlotUpdated(menteeId, slotId, topic, editId, now));
        }
    }
}
