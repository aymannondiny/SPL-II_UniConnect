package com.uniconnect.project.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "teammate_project_applications")
public class ProjectApplication {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "application_id") private Long applicationId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "project_id") private Project project;
    @Column(name = "applicant_user_id", nullable = false) private Long applicantUserId;
    @Column(length = 500) private String message;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private ProjectApplicationStatus status;
    @Column(name = "applied_at", nullable = false) private LocalDateTime appliedAt;
    @Column(name = "responded_at") private LocalDateTime respondedAt;
    protected ProjectApplication() {}
    public ProjectApplication(Project project, long applicant, String message, LocalDateTime now) {
        this.project = project; applicantUserId = applicant; this.message = message;
        status = ProjectApplicationStatus.PENDING; appliedAt = now;
    }
    public void accept(LocalDateTime now) { status = ProjectApplicationStatus.ACCEPTED; respondedAt = now; }
    public void reject(LocalDateTime now) { status = ProjectApplicationStatus.REJECTED; respondedAt = now; }
    public void cancel(LocalDateTime now) { status = ProjectApplicationStatus.CANCELLED_PROJECT_DELETED; respondedAt = now; }
    public Long getApplicationId() { return applicationId; }
    public Project getProject() { return project; }
    public Long getApplicantUserId() { return applicantUserId; }
    public String getMessage() { return message; }
    public ProjectApplicationStatus getStatus() { return status; }
    public LocalDateTime getAppliedAt() { return appliedAt; }
    public LocalDateTime getRespondedAt() { return respondedAt; }
}
