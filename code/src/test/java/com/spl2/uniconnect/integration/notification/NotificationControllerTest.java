package com.spl2.uniconnect.integration.notification;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.spl2.uniconnect.domain.notification.Notification;
import com.spl2.uniconnect.domain.notification.NotificationType;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.integration.connection.TestSecurityUtil;
import com.spl2.uniconnect.repository.notification.NotificationRepository;
import com.spl2.uniconnect.repository.user.UserRepository;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithUserDetails;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;


@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private User user1;
    private User user2;

    @BeforeEach
    void setUp() {
        user1 = userRepository.save(
                User.builder()
                        .email("alice@iut-dhaka.edu")
                        .fullName("Alice")
                        .passwordHash("password123")
                        .role(UserRole.STUDENT)
                        .emailVerified(true)
                        .build()
        );

        user2 = userRepository.save(
                User.builder()
                        .email("bob@iut-dhaka.edu")
                        .fullName("Bob")
                        .passwordHash("password123")
                        .role(UserRole.STUDENT)
                        .emailVerified(true)
                        .build()
        );
    }

    @Test
    void getNotifications_Unauthorized() throws Exception {
        mockMvc.perform(get("/api/notifications"))
                .andExpect(status().isForbidden());
    }

    @Test
    void getNotifications_Success() throws Exception {

        TestSecurityUtil.authenticateUser(user1);

        mockMvc.perform(get("/api/notifications"))
                .andExpect(status().isOk());
    }

    @Test
    void markAsRead_Success() throws Exception {

        TestSecurityUtil.authenticateUser(user1);

        Notification notification = notificationRepository.save(
                Notification.builder()
                        .user(user1)
                        .type(NotificationType.CONNECTION_REQUEST)
                        .content("Test")
                        .build()
        );

        mockMvc.perform(put("/api/notifications/" + notification.getNotificationId() + "/read")
                        .with(csrf()))
                .andExpect(status().isOk());
    }

    @Test
    void deleteNotification_Success() throws Exception {

        TestSecurityUtil.authenticateUser(user1);

        Notification notification = notificationRepository.save(
                Notification.builder()
                        .user(user1)
                        .type(NotificationType.CONNECTION_REQUEST)
                        .content("Delete me")
                        .build()
        );

        mockMvc.perform(delete("/api/notifications/" + notification.getNotificationId())
                        .with(csrf()))
                .andExpect(status().isOk());

        assertThat(notificationRepository.existsById(notification.getNotificationId()))
                .isFalse();
    }
}