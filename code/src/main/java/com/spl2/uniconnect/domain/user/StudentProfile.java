package com.spl2.uniconnect.domain.user;

import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.academic.DegreeLevel;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "student_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentProfile {

    @Id
    @Column(name = "student_id")
    private Long studentId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false, updatable = false)
    @MapsId
    private User user;

    @NotNull(message = "Programme is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "programme_id", nullable = false)
    private Programme programme;

    @NotNull(message = "Degree level is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "degree_level_id", nullable = false)
    private DegreeLevel degreeLevel;

    @NotNull(message = "Year of study is required")
    @Min(value = 1, message = "Year must be at least 1")
    @Max(value = 7, message = "Year cannot exceed 7")
    @Column(name = "year_of_study", nullable = false)
    private Integer yearOfStudy;

    @Column(name = "expected_graduation_year")
    @Min(value = 2024, message = "Invalid graduation year")
    @Max(value = 3000, message = "Invalid graduation year")
    private Integer expectedGraduationYear;

    @Size(max = 5000, message = "Bio cannot exceed 5000 characters")
    @Column(columnDefinition = "TEXT")
    private String bio;

    @Column(name = "looking_for_teammates", nullable = false)
    @Builder.Default
    private Boolean lookingForTeammates = false;

    @Column(name = "open_to_mentorship", nullable = false)
    @Builder.Default
    private Boolean openToMentorship = false;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
