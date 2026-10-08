package com.uniconnect.profile.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "interests")
public class Interest {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long interestId;
    @Column(nullable = false, unique = true, length = 60)
    private String name;
    protected Interest() {}
    public Interest(String name) { this.name = name; }
    public Long getId() { return interestId; }
    public String getName() { return name; }
}
