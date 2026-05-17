package com.spl2.uniconnect.domain.skill;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "skills")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Skill {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "skill_id")
    private Long skillId;

    @NotBlank(message = "Skill name is required")
    @Size(min = 2, max = 100, message = "Skill name must be between 2 and 100 characters")
    @Column(unique = true, nullable = false, length = 100)
    private String skillName;

    @Size(max = 50, message = "Category cannot exceed 50 characters")
    @Column(name = "category", length = 50)
    private String category; // e.g., Programming, Design, Business, etc.

}
