package com.spl2.uniconnect.domain.admin;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "moderation_actions", indexes = {
        @Index(name = "idx_mod_action_admin", columnList = "admin_id"),
        @Index(name = "idx_mod_action_target_user", columnList = "target_user_id"),
        @Index(name = "idx_mod_action_type", columnList = "action_type"),
        @Index(name = "idx_mod_action_created", columnList = "created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ModerationAction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "action_id")
    private Long actionId;

    // =====================================================
    // Admin who performed the action
    // =====================================================
    @NotNull(message = "Admin is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_id", nullable = false)
    private User admin;

    @NotNull(message = "Action type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", nullable = false, length = 50)
    private ActionType actionType;

    // =====================================================
    // Target: the user who received the action
    // =====================================================
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "target_user_id")
    private User targetUser;

    // =====================================================
    // Optional: the content that was moderated
    // e.g., target_content_type = PROJECT, target_content_id = 5
    // =====================================================
    @Enumerated(EnumType.STRING)
    @Column(name = "target_content_type", length = 50)
    private ContentType targetContentType;

    @Column(name = "target_content_id")
    private Long targetContentId;

    @NotBlank(message = "Reason for moderation action is required")
    @Column(name = "reason", nullable = false, columnDefinition = "TEXT")
    private String reason;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // =====================================================
    // Helper Methods
    // =====================================================

    /**
     * Checks if this is a user-targeted action
     */
    public boolean isUserAction() {
        return targetUser != null;
    }

    /**
     * Checks if this is a content-targeted action
     */
    public boolean isContentAction() {
        return targetContentType != null && targetContentId != null;
    }

    /**
     * Checks if this action is a ban
     */
    public boolean isBan() {
        return actionType == ActionType.BAN;
    }

    /**
     * Checks if this action is a suspension
     */
    public boolean isSuspension() {
        return actionType == ActionType.SUSPEND;
    }
}