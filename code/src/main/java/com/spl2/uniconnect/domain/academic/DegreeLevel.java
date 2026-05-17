package com.spl2.uniconnect.domain.academic;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "degree_levels")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DegreeLevel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "degree_level_id")
    private Long degreeLevelId;

    @NotBlank(message = "Degree name is required")
    @Pattern(regexp = "^(Undergraduate|Masters|PhD|Diploma|Certificate)$",
            message = "Degree name must be: Undergraduate, Masters, PhD, Diploma, or Certificate")
    @Column(name = "degree_name", unique = true, nullable = false, length = 50)
    private String degreeName;

    @NotNull(message = "Minimum years is required")
    @Min(value = 1, message = "Minimum years must be at least 1")
    @Max(value = 10, message = "Minimum years cannot exceed 10")
    @Column(name = "min_years", nullable = false)
    private Integer minYears;

    @NotNull(message = "Maximum years is required")
    @Min(value = 1, message = "Maximum years must be at least 1")
    @Max(value = 10, message = "Maximum years cannot exceed 10")
    @Column(name = "max_years", nullable = false)
    private Integer maxYears;

    @Size(max = 5000, message = "Description cannot exceed 5000 characters")
    @Column(columnDefinition = "TEXT")
    private String description;

    // Custom validation: minYears <= maxYears
    @AssertTrue(message = "Minimum years must be less than or equal to maximum years")
    public boolean isValidYearRange() {
        if (minYears == null || maxYears == null) {
            return true; // Let @NotNull handle null validation
        }
        return minYears <= maxYears;
    }
}