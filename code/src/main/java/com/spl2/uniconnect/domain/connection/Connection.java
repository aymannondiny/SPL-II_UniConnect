package com.spl2.uniconnect.domain.connection;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;


@Entity
@Table(name = "connections",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_connection_users",
                        columnNames = {"user_id_1", "user_id_2"}
                )
        },
        indexes = {
                @Index(name = "idx_connection_user1", columnList = "user_id_1"),
                @Index(name = "idx_connection_user2", columnList = "user_id_2"),
                @Index(name = "idx_connection_status", columnList = "status"),
                @Index(name = "idx_connection_requested_by", columnList = "requested_by"),
                @Index(name = "idx_connection_requested_at", columnList = "requested_at")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Connection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "connection_id")
    private Long connectionId;

    // =====================================================
    // user_id_1 is ALWAYS the smaller ID (enforced in service layer)
    // This ensures bidirectional uniqueness:
    // e.g., (user 5, user 10) and (user 10, user 5) = SAME connection
    // =====================================================

    @NotNull(message = "User 1 is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_1", nullable = false)
    private User user1;

    @NotNull(message = "User 2 is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id_2", nullable = false)
    private User user2;

    @NotNull(message = "Connection status is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private ConnectionStatus status = ConnectionStatus.PENDING;

    @NotNull(message = "Requester is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by", nullable = false)
    private User requestedBy;

    @Size(max = 500, message = "Request message cannot exceed 500 characters")
    @Column(name = "request_message", columnDefinition = "TEXT")
    private String requestMessage;

    @CreationTimestamp
    @Column(name = "requested_at", updatable = false)
    private LocalDateTime requestedAt;

    @Column(name = "accepted_at")
    private LocalDateTime acceptedAt;

    // ✅ ADDED: Track updates
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // =====================================================
    // Helper Methods
    // =====================================================

    /**
     * Checks if a specific user is part of this connection
     */
    public boolean involvesUser(User user) {
        return user1.equals(user) || user2.equals(user);
    }

    /**
     * Returns the OTHER user in the connection
     */
    public User getOtherUser(User currentUser) {
        if (user1.equals(currentUser)) return user2;
        if (user2.equals(currentUser)) return user1;
        throw new IllegalArgumentException("User is not part of this connection");
    }

    /**
     * ✅ ADDED: Get other user by ID
     */
    public User getOtherUser(Long currentUserId) {
        if (user1.getUserId().equals(currentUserId)) return user2;
        if (user2.getUserId().equals(currentUserId)) return user1;
        throw new IllegalArgumentException("User is not part of this connection");
    }

    /**
     * Checks if the connection is accepted
     */
    public boolean isAccepted() {
        return status == ConnectionStatus.ACCEPTED;
    }

    /**
     * Checks if the connection is pending
     */
    public boolean isPending() {
        return status == ConnectionStatus.PENDING;
    }

    /**
     * Accepts the connection (sets status + timestamp)
     */
    public void accept() {
        this.status = ConnectionStatus.ACCEPTED;
        this.acceptedAt = LocalDateTime.now();
    }

    /**
     * ✅ ADDED: Check if current user sent the request
     */
    public boolean isRequestedBy(User user) {
        return requestedBy.equals(user);
    }

    /**
     * ✅ ADDED: Check if current user sent the request (by ID)
     */
    public boolean isRequestedBy(Long userId) {
        return requestedBy.getUserId().equals(userId);
    }

    /**
     * ✅ ADDED: Get the receiver (the one who didn't send the request)
     */
    public User getReceiver() {
        if (user1.equals(requestedBy)) return user2;
        if (user2.equals(requestedBy)) return user1;
        throw new IllegalStateException("RequestedBy user is not part of this connection");
    }
}