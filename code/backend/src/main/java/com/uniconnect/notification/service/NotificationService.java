package com.uniconnect.notification.service;
import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.notification.dto.NotificationResponse;
import com.uniconnect.notification.repository.NotificationRepository;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.ResourceNotFoundException;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import java.time.*;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class NotificationService {
    private final ProfileAccountService accounts;
    private final NotificationRepository notifications;
    private final Clock clock;
    public NotificationService(ProfileAccountService accounts, NotificationRepository notifications, Clock clock) {
        this.accounts = accounts; this.notifications = notifications; this.clock = clock;
    }
    public PageResponse<NotificationResponse> list(SessionPrincipal actor, int page, int size) {
        accounts.lockActiveAccount(actor);
        PageValidation.check(page, size);
        var result = notifications.findByRecipientIdAndDismissedAtIsNull(actor.userId(),
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "notificationId")));
        return new PageResponse<>(result.map(NotificationResponse::from).getContent(), page, size, result.getTotalElements());
    }
    public NotificationResponse read(SessionPrincipal actor, long id) {
        accounts.lockActiveAccount(actor);
        var n = notifications.findByNotificationIdAndRecipientId(id, actor.userId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification", id));
        n.markRead(LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC));
        return NotificationResponse.from(n);
    }
}
