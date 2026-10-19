package com.uniconnect.career.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.util.Objects;

@Embeddable
public class JobSkill {
    @Column(name = "skill_id", nullable = false)
    private Long skillId;

    @Column(nullable = false)
    private boolean required;

    protected JobSkill() {}

    public JobSkill(long skillId, boolean required) {
        this.skillId = skillId;
        this.required = required;
    }

    public Long getSkillId() { return skillId; }
    public boolean isRequired() { return required; }

    @Override
    public boolean equals(Object other) {
        return this == other || other instanceof JobSkill skill && Objects.equals(skillId, skill.skillId);
    }

    @Override
    public int hashCode() { return Objects.hash(skillId); }
}
