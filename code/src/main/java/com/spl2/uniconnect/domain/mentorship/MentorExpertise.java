package com.spl2.uniconnect.domain.mentorship;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "mentor_expertise")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MentorExpertise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "expertise_id")
    private Long expertiseId;

    @NotNull(message = "Mentor is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "mentor_id", nullable = false)
    private Mentor mentor;

    @NotBlank(message = "Topic is required")
    @Size(min = 2, max = 100, message = "Topic must be between 2 and 100 characters")
    @Column(name = "topic", nullable = false, length = 100)
    private String topic;

    @Size(max = 1000, message = "Description cannot exceed 1000 characters")
    @Column(name = "description", columnDefinition = "TEXT")
    private String description;
}