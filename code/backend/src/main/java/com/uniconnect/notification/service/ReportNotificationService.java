package com.uniconnect.notification.service;
import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.repository.NotificationRepository;
import java.time.LocalDateTime;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.*;
@Service @Transactional(propagation=Propagation.MANDATORY)
public class ReportNotificationService {
    private final NotificationRepository notifications;
    public ReportNotificationService(NotificationRepository notifications){this.notifications=notifications;}
    public void resolved(long recipient,long reportId,boolean actionTaken,LocalDateTime now){
        notifications.save(Notification.reportResolved(recipient,reportId,actionTaken,now));
    }
}
