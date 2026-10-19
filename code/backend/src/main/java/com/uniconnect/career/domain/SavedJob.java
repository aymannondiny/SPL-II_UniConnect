package com.uniconnect.career.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.LocalDateTime;

@Entity
@Table(name = "career_saved_jobs", uniqueConstraints = @UniqueConstraint(
        name = "unique_career_saved_job", columnNames = {"student_user_id", "job_post_id"}))
public class SavedJob {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "saved_job_id")
    private Long savedJobId;

    @Column(name = "student_user_id", nullable = false)
    private Long studentUserId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "job_post_id", nullable = false)
    private JobPost jobPost;

    @Column(length = 1000) private String note;
    @Column(name = "saved_at", nullable = false) private LocalDateTime savedAt;
    @Column(name = "updated_at") private LocalDateTime updatedAt;

    protected SavedJob() {}

    public SavedJob(long studentUserId, JobPost jobPost, String note, LocalDateTime now) {
        this.studentUserId = studentUserId;
        this.jobPost = jobPost;
        this.note = note;
        this.savedAt = now;
    }

    public void updateNote(String note, LocalDateTime now) {
        this.note = note;
        this.updatedAt = now;
    }

    public Long getSavedJobId() { return savedJobId; }
    public Long getStudentUserId() { return studentUserId; }
    public JobPost getJobPost() { return jobPost; }
    public String getNote() { return note; }
    public LocalDateTime getSavedAt() { return savedAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
