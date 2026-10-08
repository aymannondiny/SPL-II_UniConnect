package com.uniconnect.profile.domain;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.*;

@Entity
@Table(name = "personal_profiles")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "profile_type", length = 20)
public abstract class PersonalProfile {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long profileId;
    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "programme_degree_id", nullable = false)
    private ProgrammeDegree programmeDegree;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30)
    private ProfileVisibility detailsVisibility = ProfileVisibility.CONNECTIONS_ONLY;
    @Column(length = 2000) private String bio;
    @Column(length = 2048) private String profilePhotoUrl;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    @ManyToMany
    @JoinTable(name = "profile_skills", joinColumns = @JoinColumn(name = "profile_id"), inverseJoinColumns = @JoinColumn(name = "skill_id"))
    private Set<Skill> skills = new HashSet<>();
    @ManyToMany
    @JoinTable(name = "profile_interests", joinColumns = @JoinColumn(name = "profile_id"), inverseJoinColumns = @JoinColumn(name = "interest_id"))
    private Set<Interest> interests = new HashSet<>();
    protected PersonalProfile() {}
    protected PersonalProfile(User user, LocalDateTime now) { this.user = user; this.createdAt = now; }
    public void updateCommon(ProgrammeDegree degree, String bio, String photo, Set<Skill> skills, Set<Interest> interests, LocalDateTime now) {
        this.programmeDegree = degree;
        this.bio = bio;
        this.profilePhotoUrl = photo;
        this.skills.clear(); this.skills.addAll(skills);
        this.interests.clear(); this.interests.addAll(interests);
        this.updatedAt = now;
    }
    protected void touch(LocalDateTime now) { updatedAt = now; }
    public ProfileVisibility getDetailsVisibility() { return detailsVisibility; }
    public void setDetailsVisibility(ProfileVisibility visibility, LocalDateTime now) {
        detailsVisibility = java.util.Objects.requireNonNull(visibility);
        touch(now);
    }
    public Long getId() { return profileId; }
    public User getUser() { return user; }
    public ProgrammeDegree getProgrammeDegree() { return programmeDegree; }
    public String getBio() { return bio; }
    public String getProfilePhotoUrl() { return profilePhotoUrl; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public Set<Skill> getSkills() { return Collections.unmodifiableSet(skills); }
    public Set<Interest> getInterests() { return Collections.unmodifiableSet(interests); }
}
