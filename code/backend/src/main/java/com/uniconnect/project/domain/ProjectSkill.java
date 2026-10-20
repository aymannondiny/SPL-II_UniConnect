package com.uniconnect.project.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.util.Objects;

@Embeddable
public class ProjectSkill {
    @Column(name = "skill_id", nullable = false) private Long skillId;
    @Column(nullable = false) private boolean required;
    protected ProjectSkill() {}
    public ProjectSkill(long skillId, boolean required) { this.skillId = skillId; this.required = required; }
    public Long getSkillId() { return skillId; }
    public boolean isRequired() { return required; }
    @Override public boolean equals(Object other) {
        return this == other || other instanceof ProjectSkill skill && Objects.equals(skillId, skill.skillId);
    }
    @Override public int hashCode() { return Objects.hash(skillId); }
}
