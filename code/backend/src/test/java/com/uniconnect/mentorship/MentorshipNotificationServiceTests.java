package com.uniconnect.mentorship;

import com.uniconnect.notification.domain.Notification;
import com.uniconnect.notification.domain.NotificationType;
import com.uniconnect.notification.repository.NotificationRepository;
import com.uniconnect.notification.service.MentorshipNotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class MentorshipNotificationServiceTests {

    private NotificationRepository repository;
    private MentorshipNotificationService service;
    private final LocalDateTime now = LocalDateTime.parse("2026-10-21T10:00:00");

    @BeforeEach
    void setUp() {
        repository = mock(NotificationRepository.class);
        service = new MentorshipNotificationService(repository);
    }

    @Test
    void slotJoinedDispatchesToBothMentorAndMentee() {
        service.slotJoined(10L, 20L, 100L, 1L, "Alice Smith", "Data Structures", now);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(repository, times(2)).save(captor.capture());

        List<Notification> saved = captor.getAllValues();
        assertThat(saved).hasSize(2);

        Notification mentorNotif = saved.get(0);
        assertThat(mentorNotif.getType()).isEqualTo(NotificationType.MENTORSHIP_SLOT_JOINED);
        assertThat(mentorNotif.getTitle()).isEqualTo("New mentee enrolled");
        assertThat(mentorNotif.getMessage()).contains("Alice Smith");

        Notification menteeNotif = saved.get(1);
        assertThat(menteeNotif.getType()).isEqualTo(NotificationType.MENTORSHIP_SLOT_JOINED);
        assertThat(menteeNotif.getTitle()).isEqualTo("Enrolled in session");
        assertThat(menteeNotif.getMessage()).contains("Data Structures");
    }

    @Test
    void slotLeftDispatchesToMentor() {
        service.slotLeft(10L, 100L, 1L, "Bob Rahman", "Graph Theory", now);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(repository, times(1)).save(captor.capture());

        Notification notif = captor.getValue();
        assertThat(notif.getType()).isEqualTo(NotificationType.MENTORSHIP_SLOT_LEFT);
        assertThat(notif.getTitle()).isEqualTo("Mentee left session");
        assertThat(notif.getMessage()).contains("Bob Rahman");
    }

    @Test
    void slotCancelledDispatchesToAllEnrolledMentees() {
        service.slotCancelled(List.of(20L, 21L, 22L), 100L, "Machine Learning", now);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(repository, times(3)).save(captor.capture());

        List<Notification> saved = captor.getAllValues();
        assertThat(saved).allMatch(n -> n.getType() == NotificationType.MENTORSHIP_SLOT_CANCELLED);
        assertThat(saved.get(0).getTitle()).isEqualTo("Mentorship session cancelled");
    }

    @Test
    void slotUpdatedDispatchesToAllEnrolledMentees() {
        service.slotUpdated(List.of(20L, 21L), 100L, "Linear Algebra", "edit-1", now);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(repository, times(2)).save(captor.capture());

        List<Notification> saved = captor.getAllValues();
        assertThat(saved).allMatch(n -> n.getType() == NotificationType.MENTORSHIP_SLOT_UPDATED);
        assertThat(saved.get(0).getTitle()).isEqualTo("Mentorship session updated");
    }
}
