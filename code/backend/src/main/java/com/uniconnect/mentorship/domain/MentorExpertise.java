package com.uniconnect.mentorship.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "mentor_expertise")
public class MentorExpertise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "expertise_id")
    private Long expertiseId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "mentor_profile_id", nullable = false)
    private MentorProfile mentorProfile;

    @Column(nullable = false, length = 100)
    private String topic;

    @Column(length = 1000)
    private String description;

    protected MentorExpertise() {}

    public MentorExpertise(MentorProfile mentorProfile, String topic, String description) {
        this.mentorProfile = mentorProfile;
        this.topic = topic;
        this.description = description;
    }

    public Long getId() {
        return expertiseId;
    }

    public MentorProfile getMentorProfile() {
        return mentorProfile;
    }

    public String getTopic() {
        return topic;
    }

    public String getDescription() {
        return description;
    }

    public void update(String topic, String description) {
        this.topic = topic;
        this.description = description;
    }
}
