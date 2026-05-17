package com.spl2.uniconnect.domain.mentorship;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "mentorship_enrollments",
        uniqueConstraints = @UniqueConstraint(columnNames = {"slot_id", "mentee_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MentorshipEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "enrollment_id")
    private Long enrollmentId;

    @NotNull(message = "Slot is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "slot_id", nullable = false)
    private MentorshipSlot slot;

    @NotNull(message = "Mentee is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mentee_id", nullable = false)
    private User mentee;

    @Size(max = 500, message = "Message cannot exceed 500 characters")
    @Column(name = "message", columnDefinition = "TEXT")
    private String message;

    @Size(max = 1000, message = "Learning goals cannot exceed 1000 characters")
    @Column(name = "learning_goals", columnDefinition = "TEXT")
    private String learningGoals;

    @CreationTimestamp
    @Column(name = "enrolled_at", updatable = false)
    private LocalDateTime enrolledAt;

    @Column(name = "left_at")
    private LocalDateTime leftAt;
}