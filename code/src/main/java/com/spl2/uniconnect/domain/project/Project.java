package com.spl2.uniconnect.domain.project;

import com.spl2.uniconnect.domain.user.User;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "projects")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Project {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "project_id")
    private Long projectId;

    @NotNull(message = "Creator is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creator_id", nullable = false)
    private User creator;

    @NotBlank(message = "Project title is required")
    @Size(min = 5, max = 200, message = "Title must be between 5 and 200 characters")
    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @NotBlank(message = "Project description is required")
    @Size(min = 20, max = 5000, message = "Description must be between 20 and 5000 characters")
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @NotNull(message = "Number of teammates needed is required")
    @Min(value = 1, message = "At least 1 teammate needed")
    @Max(value = 10, message = "Maximum 10 teammates allowed")
    @Column(name = "teammates_needed", nullable = false)
    private Integer teammatesNeeded;

    @Size(max = 100, message = "Course name cannot exceed 100 characters")
    @Column(name = "course_name", length = 100)
    private String courseName;

    @Column(name = "application_deadline")
    private LocalDate applicationDeadline;

    @Size(max = 100, message = "Project duration cannot exceed 100 characters")
    @Column(name = "project_duration", length = 100)
    private String projectDuration;

    @Builder.Default
    @NotNull(message = "Status is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private ProjectStatus status = ProjectStatus.Open;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}