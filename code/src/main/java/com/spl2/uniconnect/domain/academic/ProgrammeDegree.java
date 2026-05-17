package com.spl2.uniconnect.domain.academic;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "programme_degrees",
        uniqueConstraints = @UniqueConstraint(columnNames = {"programme_id", "degree_level_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProgrammeDegree {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "programme_degree_id")
    private Long programmeDegreeId;

    @NotNull(message = "Programme is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "programme_id", nullable = false)
    private Programme programme;

    @NotNull(message = "Degree level is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "degree_level_id", nullable = false)
    private DegreeLevel degreeLevel;

    @NotNull(message = "Duration is required")
    @Min(value = 1, message = "Duration must be at least 1 year")
    @Max(value = 10, message = "Duration cannot exceed 10 years")
    @Column(name = "duration_years", nullable = false)
    private Integer durationYears;
}