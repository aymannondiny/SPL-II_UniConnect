package com.spl2.uniconnect.domain.career;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "job_postings", indexes = {
        @Index(name = "idx_job_posted_by", columnList = "posted_by"),
        @Index(name = "idx_job_type", columnList = "job_type"),
        @Index(name = "idx_job_deadline", columnList = "application_deadline")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobPosting {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "job_id")
    private Long jobId;

    @NotNull(message = "Job poster is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "posted_by", nullable = false)
    private User postedBy;

    @NotBlank(message = "Job title is required")
    @Size(max = 255, message = "Title cannot exceed 255 characters")
    @Column(name = "title", nullable = false)
    private String title;

    @NotBlank(message = "Company name is required")
    @Size(max = 255, message = "Company name cannot exceed 255 characters")
    @Column(name = "company_name", nullable = false)
    private String companyName;

    @NotNull(message = "Job type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "job_type", nullable = false, length = 50)
    private JobType jobType;

    @NotBlank(message = "Location is required")
    @Size(max = 255, message = "Location cannot exceed 255 characters")
    @Column(name = "location", nullable = false)
    private String location;

    @NotBlank(message = "Job description is required")
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @Column(name = "requirements", columnDefinition = "TEXT")
    private String requirements;

    @Size(max = 500, message = "Application link cannot exceed 500 characters")
    @Column(name = "application_link", length = 500)
    private String applicationLink;

    @Email(message = "Invalid email format")
    @Size(max = 255, message = "Email cannot exceed 255 characters")
    @Column(name = "application_email")
    private String applicationEmail;

    @Column(name = "application_deadline")
    private LocalDate applicationDeadline;

    @Size(max = 100, message = "Salary range cannot exceed 100 characters")
    @Column(name = "salary_range", length = 100)
    private String salaryRange;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Relationships
    @OneToMany(mappedBy = "jobPosting", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private Set<JobSkill> jobSkills = new HashSet<>();

    @OneToMany(mappedBy = "jobPosting", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private Set<SavedJob> savedByUsers = new HashSet<>();

    // Helper methods
    public void addJobSkill(JobSkill jobSkill) {
        jobSkills.add(jobSkill);
        jobSkill.setJobPosting(this);
    }

    public void removeJobSkill(JobSkill jobSkill) {
        jobSkills.remove(jobSkill);
        jobSkill.setJobPosting(null);
    }

    public boolean isDeadlinePassed() {
        return applicationDeadline != null && LocalDate.now().isAfter(applicationDeadline);
    }

    public boolean isActive() {
        return !isDeadlinePassed();
    }
}
