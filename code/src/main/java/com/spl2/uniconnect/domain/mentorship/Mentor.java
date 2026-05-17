package com.spl2.uniconnect.domain.mentorship;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "mentors")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Mentor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "mentor_id")
    private Long mentorId;

    @NotNull(message = "User is required")
    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true, nullable = false)
    private User user;

    @Size(max = 5000, message = "Bio cannot exceed 5000 characters")
    @Column(name = "bio", columnDefinition = "TEXT")
    private String bio;

    @NotBlank(message = "Mentoring approach is required")
    @Size(min = 10, max = 5000, message = "Mentoring approach must be between 10 and 5000 characters")
    @Column(name = "mentoring_approach", nullable = false, columnDefinition = "TEXT")
    private String mentoringApproach;

    @Builder.Default
    @NotNull(message = "Status is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private MentorStatus status = MentorStatus.Available;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}