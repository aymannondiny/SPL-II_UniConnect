package com.spl2.uniconnect.unit.service.notification;

import com.spl2.uniconnect.domain.notification.Notification;
import com.spl2.uniconnect.domain.notification.NotificationType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.notification.NotificationRepository;
import com.spl2.uniconnect.service.notification.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.*;

import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User user1;
    private User user2;

    @BeforeEach
    void setup() {
        MockitoAnnotations.openMocks(this);

        user1 = User.builder()
                .userId(1L)
                .fullName("Alice")
                .build();

        user2 = User.builder()
                .userId(2L)
                .fullName("Bob")
                .build();
    }

    @Test
    void sendConnectionRequestNotification_ShouldSave() {
        notificationService.sendConnectionRequestNotification(user1, user2);

        verify(notificationRepository, times(1)).save(any(Notification.class));
    }

    @Test
    void sendConnectionAcceptedNotification_ShouldSave() {
        notificationService.sendConnectionAcceptedNotification(user1, user2);

        verify(notificationRepository).save(any(Notification.class));
    }

    @Test
    void getById_Success() {
        Notification notification = Notification.builder()
                .notificationId(1L)
                .user(user1)
                .build();

        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));

        Notification result = notificationService.getById(1L, 1L);

        assertThat(result).isNotNull();
    }

    @Test
    void getById_NotFound() {
        when(notificationRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.getById(1L, 1L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void getById_Forbidden() {
        Notification notification = Notification.builder()
                .notificationId(1L)
                .user(user1)
                .build();

        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));

        assertThatThrownBy(() -> notificationService.getById(1L, 2L))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void markAsRead_ShouldUpdate() {
        Notification notification = Notification.builder()
                .notificationId(1L)
                .user(user1)
                .isRead(false)
                .build();

        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));

        notificationService.markAsRead(1L, 1L);

        assertThat(notification.getIsRead()).isTrue();
    }

    @Test
    void deleteNotification_Success() {
        Notification notification = Notification.builder()
                .notificationId(1L)
                .user(user1)
                .build();

        when(notificationRepository.findById(1L)).thenReturn(Optional.of(notification));

        notificationService.deleteNotification(1L, 1L);

        verify(notificationRepository).delete(notification);
    }
}