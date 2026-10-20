package com.uniconnect.project.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;

@Entity
@Table(name = "teammate_projects")
public class Project {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "project_id") private Long projectId;
    @Column(name = "creator_user_id", nullable = false) private Long creatorUserId;
    @Column(nullable = false, length = 200) private String title;
    @Column(nullable = false, length = 5000) private String description;
    @Column(name = "team_size_limit", nullable = false) private int teamSizeLimit;
    @Column(length = 200) private String duration;
    @Column(name = "course_name", length = 200) private String courseName;
    @Column(name = "application_deadline", nullable = false) private LocalDate applicationDeadline;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private ProjectStatus status;
    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
    @Column(name = "closed_at") private LocalDateTime closedAt;
    @Column(name = "deleted_at") private LocalDateTime deletedAt;
    @Column(name = "creator_redacted_at") private LocalDateTime creatorRedactedAt;
    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "teammate_project_skills", joinColumns = @JoinColumn(name = "project_id"))
    private Set<ProjectSkill> skills = new LinkedHashSet<>();

    protected Project() {}
    public Project(long creator, String title, String description, int limit, String duration,
            String courseName, LocalDate deadline, Set<ProjectSkill> skills, LocalDateTime now) {
        creatorUserId = creator; status = ProjectStatus.OPEN; createdAt = now;
        update(title, description, limit, duration, courseName, deadline, skills, now);
    }
    public void update(String title, String description, int limit, String duration,
            String courseName, LocalDate deadline, Set<ProjectSkill> skills, LocalDateTime now) {
        this.title = title; this.description = description; teamSizeLimit = limit;
        this.duration = duration; this.courseName = courseName; applicationDeadline = deadline;
        this.skills.clear(); this.skills.addAll(skills); updatedAt = now;
    }
    public void close(LocalDateTime now) { status = ProjectStatus.CLOSED; closedAt = now; updatedAt = now; }
    public void reopen(LocalDateTime now) { status = ProjectStatus.OPEN; closedAt = null; updatedAt = now; }
    public void delete(LocalDateTime now) { status = ProjectStatus.DELETED; deletedAt = now; updatedAt = now; }
    public void redactCreator(LocalDateTime now) {
        creatorRedactedAt = now;
        if (status != ProjectStatus.DELETED) delete(now); else updatedAt = now;
    }
    public boolean expired(LocalDate today) { return applicationDeadline.isBefore(today); }
    public ProjectAvailability availability(LocalDate today, long members) {
        if (status == ProjectStatus.CLOSED) return ProjectAvailability.CLOSED;
        if (expired(today)) return ProjectAvailability.EXPIRED;
        return members >= teamSizeLimit ? ProjectAvailability.FULL : ProjectAvailability.AVAILABLE;
    }
    public Long getProjectId() { return projectId; }
    public Long getCreatorUserId() { return creatorUserId; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public int getTeamSizeLimit() { return teamSizeLimit; }
    public String getDuration() { return duration; }
    public String getCourseName() { return courseName; }
    public LocalDate getApplicationDeadline() { return applicationDeadline; }
    public ProjectStatus getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public LocalDateTime getClosedAt() { return closedAt; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatorRedactedAt() { return creatorRedactedAt; }
    public Set<ProjectSkill> getSkills() { return Set.copyOf(skills); }
}
