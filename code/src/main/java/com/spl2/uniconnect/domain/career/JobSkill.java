package com.spl2.uniconnect.domain.career;

import com.spl2.uniconnect.domain.skill.Skill;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import lombok.*;

@Entity
@Table(name = "job_skills",
        uniqueConstraints = {
                @UniqueConstraint(name = "uk_job_skill", columnNames = {"job_id", "skill_id"})
        },
        indexes = {
                @Index(name = "idx_job_skill_job", columnList = "job_id"),
                @Index(name = "idx_job_skill_skill", columnList = "skill_id")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobSkill {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "job_skill_id")
    private Long jobSkillId;

    @NotNull(message = "Job posting is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "job_id", nullable = false)
    private JobPosting jobPosting;

    @NotNull(message = "Skill is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "skill_id", nullable = false)
    private Skill skill;

}
