package com.spl2.uniconnect.domain.notification;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications", indexes = {
        @Index(name = "idx_notification_user", columnList = "user_id"),
        @Index(name = "idx_notification_is_read", columnList = "is_read"),
        @Index(name = "idx_notification_created", columnList = "created_at"),
        @Index(name = "idx_notification_user_read", columnList = "user_id, is_read"),
        @Index(name = "idx_notification_type", columnList = "type")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "notification_id")
    private Long notificationId;

    // =====================================================
    // The user who RECEIVES this notification
    // =====================================================
    @NotNull(message = "Notification recipient is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @NotNull(message = "Notification type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 50)
    private NotificationType type;

    @NotBlank(message = "Notification content is required")
    @Size(max = 500, message = "Content cannot exceed 500 characters")
    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    // =====================================================
    // Polymorphic reference: points to the related entity
    // e.g., reference_id = 5, reference_type = "project"
    // means "go look at project with ID 5"
    // =====================================================
    @Column(name = "reference_id")
    private Long referenceId;

    @Size(max = 50, message = "Reference type cannot exceed 50 characters")
    @Column(name = "reference_type", length = 50)
    private String referenceType;

    @Column(name = "is_read", nullable = false)
    @Builder.Default
    private Boolean isRead = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // =====================================================
    // Helper Methods
    // =====================================================

    /**
     * Marks notification as read
     */
    public void markAsRead() {
        this.isRead = true;
    }

    /**
     * Checks if notification is unread
     */
    public boolean isUnread() {
        return !isRead;
    }

    /**
     * Factory method: create a notification easily
     */
    public static Notification create(
            User recipient,
            NotificationType type,
            String content,
            Long referenceId,
            String referenceType) {

        return Notification.builder()
                .user(recipient)
                .type(type)
                .content(content)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .isRead(false)
                .build();
    }
}
