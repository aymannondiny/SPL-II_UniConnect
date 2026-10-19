package com.uniconnect.career.domain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "career_job_posts")
public class JobPost {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "job_post_id")
    private Long jobPostId;

    @Column(name = "author_user_id", nullable = false)
    private Long authorUserId;
    @Column(nullable = false, length = 200) private String title;
    @Column(name = "company_name", nullable = false, length = 200) private String companyName;
    @Column(nullable = false, length = 5000) private String description;
    @Column(nullable = false, length = 5000) private String qualifications;
    @Column(length = 200) private String location;
    @Enumerated(EnumType.STRING) @Column(name = "employment_type", nullable = false, length = 30)
    private EmploymentType employmentType;
    @Enumerated(EnumType.STRING) @Column(name = "work_mode", nullable = false, length = 20)
    private WorkMode workMode;
    @Column(name = "salary_range", length = 200) private String salaryRange;
    @Column(name = "application_url", length = 2048) private String applicationUrl;
    @Column(name = "application_email", length = 320) private String applicationEmail;
    @Column(name = "application_deadline", nullable = false) private LocalDate applicationDeadline;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private JobPostStatus status;
    @Column(name = "posted_at", nullable = false) private LocalDateTime postedAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
    @Column(name = "closed_at") private LocalDateTime closedAt;
    @Column(name = "removed_at") private LocalDateTime removedAt;
    @Column(name = "author_redacted_at") private LocalDateTime authorRedactedAt;

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "career_job_skills", joinColumns = @JoinColumn(name = "job_post_id"))
    private Set<JobSkill> skills = new LinkedHashSet<>();

    protected JobPost() {}

    public JobPost(long authorUserId, String title, String companyName, String description,
            String qualifications, String location, EmploymentType employmentType, WorkMode workMode,
            String salaryRange, String applicationUrl, String applicationEmail, LocalDate applicationDeadline,
            Set<JobSkill> skills, LocalDateTime now) {
        this.authorUserId = authorUserId;
        updateFields(title, companyName, description, qualifications, location, employmentType, workMode,
                salaryRange, applicationUrl, applicationEmail, applicationDeadline, skills, now);
        this.status = JobPostStatus.PUBLISHED;
        this.postedAt = now;
    }

    public void update(String title, String companyName, String description, String qualifications,
            String location, EmploymentType employmentType, WorkMode workMode, String salaryRange,
            String applicationUrl, String applicationEmail, LocalDate applicationDeadline,
            Set<JobSkill> skills, LocalDateTime now) {
        updateFields(title, companyName, description, qualifications, location, employmentType, workMode,
                salaryRange, applicationUrl, applicationEmail, applicationDeadline, skills, now);
    }

    private void updateFields(String title, String companyName, String description, String qualifications,
            String location, EmploymentType employmentType, WorkMode workMode, String salaryRange,
            String applicationUrl, String applicationEmail, LocalDate applicationDeadline,
            Set<JobSkill> skills, LocalDateTime now) {
        this.title = title;
        this.companyName = companyName;
        this.description = description;
        this.qualifications = qualifications;
        this.location = location;
        this.employmentType = employmentType;
        this.workMode = workMode;
        this.salaryRange = salaryRange;
        this.applicationUrl = applicationUrl;
        this.applicationEmail = applicationEmail;
        this.applicationDeadline = applicationDeadline;
        this.skills.clear();
        this.skills.addAll(skills);
        this.updatedAt = now;
    }

    public boolean isExpired(LocalDate date) { return applicationDeadline.isBefore(date); }
    public boolean isActive(LocalDate date) {
        return status == JobPostStatus.PUBLISHED && authorRedactedAt == null && !isExpired(date);
    }

    public CareerPostAvailability availability(LocalDate date) {
        if (status == JobPostStatus.REMOVED) return CareerPostAvailability.REMOVED;
        if (authorRedactedAt != null) return CareerPostAvailability.UNAVAILABLE;
        if (status == JobPostStatus.CLOSED) return CareerPostAvailability.CLOSED;
        return isExpired(date) ? CareerPostAvailability.EXPIRED : CareerPostAvailability.PUBLISHED;
    }

    public void close(LocalDateTime now) {
        status = JobPostStatus.CLOSED;
        closedAt = now;
        updatedAt = now;
    }

    public void redactAuthor(LocalDateTime now) {
        authorRedactedAt = now;
        applicationUrl = null;
        applicationEmail = null;
        updatedAt = now;
    }

    public Long getJobPostId() { return jobPostId; }
    public Long getAuthorUserId() { return authorUserId; }
    public String getTitle() { return title; }
    public String getCompanyName() { return companyName; }
    public String getDescription() { return description; }
    public String getQualifications() { return qualifications; }
    public String getLocation() { return location; }
    public EmploymentType getEmploymentType() { return employmentType; }
    public WorkMode getWorkMode() { return workMode; }
    public String getSalaryRange() { return salaryRange; }
    public String getApplicationUrl() { return applicationUrl; }
    public String getApplicationEmail() { return applicationEmail; }
    public LocalDate getApplicationDeadline() { return applicationDeadline; }
    public JobPostStatus getStatus() { return status; }
    public LocalDateTime getPostedAt() { return postedAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public LocalDateTime getClosedAt() { return closedAt; }
    public LocalDateTime getRemovedAt() { return removedAt; }
    public LocalDateTime getAuthorRedactedAt() { return authorRedactedAt; }
    public Set<JobSkill> getSkills() { return Set.copyOf(skills); }
}
