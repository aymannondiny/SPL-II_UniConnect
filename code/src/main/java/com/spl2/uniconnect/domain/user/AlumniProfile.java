package com.spl2.uniconnect.domain.user;

import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.academic.DegreeLevel;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.time.Year;

@Entity
@Table(name = "alumni_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AlumniProfile {

    @Id
    @Column(name = "alumni_id")
    private Long alumniId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "alumni_id", nullable = false, updatable = false)
    @MapsId
    private User user;

    @NotNull(message = "Graduation year is required")
    @Column(name = "graduation_year", nullable = false)
    private Integer graduationYear;

    @NotNull(message = "Programme is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "programme_id", nullable = false)
    private Programme programme;

    @NotNull(message = "Degree level is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "degree_level_id", nullable = false)
    private DegreeLevel degreeLevel;

    @Size(max = 255, message = "Company name cannot exceed 255 characters")
    @Column(name = "current_company", length = 255)
    private String currentCompany;

    @Size(max = 255, message = "Position cannot exceed 255 characters")
    @Column(name = "current_position", length = 255)
    private String currentPosition;

    @Size(max = 100, message = "Industry cannot exceed 100 characters")
    @Column(name = "industry", length = 100)
    private String industry;

    @Size(max = 5000, message = "Career background cannot exceed 5000 characters")
    @Column(name = "career_background", columnDefinition = "TEXT")
    private String careerBackground;

    @Size(max = 500, message = "LinkedIn URL cannot exceed 500 characters")
    @Column(name = "linkedin_url", length = 500)
    @Pattern(regexp = "^(https?://)?([\\da-z.-]+)\\.([a-z.]{2,6})?(/[/\\w .-]*)?/?$|^$",
            message = "Invalid URL format")
    private String linkedinUrl;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Validation: graduation year must be in the past or current year
    @AssertTrue(message = "Graduation year must be in the past or current year")
    public boolean isValidGraduationYear() {
        if (graduationYear == null) {
            return true; // Let @NotNull handle validation
        }
        int currentYear = Year.now().getValue();
        return graduationYear <= currentYear;
    }
}