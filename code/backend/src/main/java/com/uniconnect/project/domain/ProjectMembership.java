package com.uniconnect.project.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @Table(name = "teammate_project_memberships")
public class ProjectMembership {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "membership_id") private Long membershipId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "project_id") private Project project;
    @Column(name = "member_user_id", nullable = false) private Long memberUserId;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20) private ProjectMemberRole role;
    @Column(name = "creator_project_id") private Long creatorProjectId;
    @Column(name = "joined_at", nullable = false) private LocalDateTime joinedAt;
    protected ProjectMembership() {}
    public ProjectMembership(Project project, long member, ProjectMemberRole role, LocalDateTime now) {
        this.project = project; memberUserId = member; this.role = role;
        creatorProjectId = role == ProjectMemberRole.CREATOR ? project.getProjectId() : null; joinedAt = now;
    }
    public Long getMembershipId() { return membershipId; }
    public Project getProject() { return project; }
    public Long getMemberUserId() { return memberUserId; }
    public ProjectMemberRole getRole() { return role; }
    public LocalDateTime getJoinedAt() { return joinedAt; }
}
