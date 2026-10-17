package com.uniconnect.profile.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "skills")
public class Skill {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long skillId;
    @Column(nullable = false, unique = true, length = 60)
    private String name;
    @Column(length = 100)
    private String category;
    public String getCategory() { return category; }
    protected Skill() {}
    public Skill(String name) { this.name = name; }
    public Long getId() { return skillId; }
    public String getName() { return name; }
}
