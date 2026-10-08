package com.uniconnect.profile.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "programmes")
public class Programme {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long programmeId;
    @Column(nullable = false, length = 150)
    private String programmeName;
    @Column(nullable = false, unique = true, length = 30)
    private String programmeCode;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    protected Programme() {}
    public Programme(String name, String code, Department department) { rename(name, code); this.department = department; }
    public void rename(String name, String code) { this.programmeName = name; this.programmeCode = code; }
    public Long getId() { return programmeId; }
    public String getName() { return programmeName; }
    public String getCode() { return programmeCode; }
    public Department getDepartment() { return department; }
}
