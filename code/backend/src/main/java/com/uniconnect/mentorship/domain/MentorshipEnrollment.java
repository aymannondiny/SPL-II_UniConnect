package com.uniconnect.mentorship.domain;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "mentorship_enrollments", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"slot_id", "mentee_id"})
})
public class MentorshipEnrollment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "enrollment_id")
    private Long enrollmentId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "slot_id", nullable = false)
    private MentorshipSlot slot;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "mentee_id", nullable = false)
    private User mentee;

    @Column(name = "join_message", length = 300)
    private String joinMessage;

    @Column(name = "learning_goal", length = 1000)
    private String learningGoal;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EnrollmentStatus status = EnrollmentStatus.ACTIVE;

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt;

    @Column(name = "left_at")
    private LocalDateTime leftAt;

    protected MentorshipEnrollment() {}

    public MentorshipEnrollment(
            MentorshipSlot slot,
            User mentee,
            String joinMessage,
            String learningGoal,
            LocalDateTime now
    ) {
        this.slot = slot;
        this.mentee = mentee;
        this.joinMessage = joinMessage;
        this.learningGoal = learningGoal;
        this.status = EnrollmentStatus.ACTIVE;
        this.joinedAt = now;
    }

    public void leave(LocalDateTime now) {
        this.status = EnrollmentStatus.LEFT;
        this.leftAt = now;
    }

    public void cancel(LocalDateTime now) {
        this.status = EnrollmentStatus.CANCELLED;
        this.leftAt = now;
    }

    public void reEnroll(String joinMessage, String learningGoal, LocalDateTime now) {
        this.status = EnrollmentStatus.ACTIVE;
        this.joinMessage = joinMessage;
        this.learningGoal = learningGoal;
        this.joinedAt = now;
        this.leftAt = null;
    }

    public Long getId() {
        return enrollmentId;
    }

    public MentorshipSlot getSlot() {
        return slot;
    }

    public User getMentee() {
        return mentee;
    }

    public String getJoinMessage() {
        return joinMessage;
    }

    public String getLearningGoal() {
        return learningGoal;
    }

    public EnrollmentStatus getStatus() {
        return status;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public LocalDateTime getLeftAt() {
        return leftAt;
    }
}
