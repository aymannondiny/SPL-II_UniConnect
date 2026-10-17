package com.uniconnect.profile.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "departments")
public class Department {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long departmentId;
    @Column(nullable = false, length = 150)
    private String departmentName;
    @Column(nullable = false, unique = true, length = 30)
    private String departmentCode;

    protected Department() {}
    public Department(String name, String code) { rename(name, code); }
    public void rename(String name, String code) { this.departmentName = name; this.departmentCode = code; }
    public Long getId() { return departmentId; }
    public String getName() { return departmentName; }
    public String getCode() { return departmentCode; }
}
