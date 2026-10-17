package com.uniconnect.mentorship.domain;

import com.uniconnect.profile.domain.Skill;
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

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

    @Column(length = 1000)
    private String description;

    protected MentorExpertise() {}

    public MentorExpertise(MentorProfile mentorProfile, Skill skill, String description) {
        this.mentorProfile = mentorProfile;
        this.skill = skill;
        this.description = description;
    }

    public Long getId() {
        return expertiseId;
    }

    public MentorProfile getMentorProfile() {
        return mentorProfile;
    }

    public Skill getSkill() {
        return skill;
    }

    public String getTopic() {
        return skill != null ? skill.getName() : null;
    }

    public String getDescription() {
        return description;
    }

    public void update(Skill skill, String description) {
        this.skill = skill;
        this.description = description;
    }
}
