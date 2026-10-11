package com.uniconnect.mentorship.domain;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Entity
@Table(name = "mentor_profiles")
public class MentorProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "mentor_profile_id")
    private Long mentorProfileId;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(nullable = false, length = 5000)
    private String mentoringBio;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MentorStatus status = MentorStatus.AVAILABLE;

    @Column(nullable = false)
    private LocalDateTime registeredAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "mentorProfile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MentorExpertise> expertise = new ArrayList<>();

    protected MentorProfile() {}

    public MentorProfile(User user, String mentoringBio, LocalDateTime now) {
        this.user = user;
        this.mentoringBio = mentoringBio;
        this.status = MentorStatus.AVAILABLE;
        this.registeredAt = now;
        this.updatedAt = now;
    }

    public void addExpertise(String topic, String description) {
        this.expertise.add(new MentorExpertise(this, topic, description));
    }

    public void clearAndSetExpertise(List<MentorExpertise> newExpertise) {
        this.expertise.clear();
        this.expertise.addAll(newExpertise);
    }

    public void updateBio(String newBio, LocalDateTime now) {
        this.mentoringBio = newBio;
        this.updatedAt = now;
    }

    public void setStatus(MentorStatus newStatus, LocalDateTime now) {
        this.status = newStatus;
        this.updatedAt = now;
    }

    public Long getId() {
        return mentorProfileId;
    }

    public User getUser() {
        return user;
    }

    public String getMentoringBio() {
        return mentoringBio;
    }

    public MentorStatus getStatus() {
        return status;
    }

    public LocalDateTime getRegisteredAt() {
        return registeredAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public List<MentorExpertise> getExpertise() {
        return Collections.unmodifiableList(expertise);
    }
}
