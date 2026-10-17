package com.uniconnect.profile.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "programme_degrees", uniqueConstraints = @UniqueConstraint(columnNames = {"programme_id", "degree_level"}))
public class ProgrammeDegree {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long programmeDegreeId;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "programme_id", nullable = false)
    private Programme programme;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private DegreeLevel degreeLevel;
    @Column(nullable = false) private Integer durationYears;
    @Column(nullable = false) private Integer minimumYear;
    @Column(nullable = false) private Integer maximumYear;
    @Column(nullable = false) private boolean active;
    protected ProgrammeDegree() {}
    public ProgrammeDegree(Programme programme, DegreeLevel level, int duration, int min, int max, boolean active) {
        this.programme = programme;
        this.degreeLevel = level;
        revise(duration, min, max, active);
    }
    public void revise(int duration, int min, int max, boolean active) {
        if (duration < 1 || min < 1 || max < min) throw new IllegalArgumentException("Invalid study-year range");
        this.durationYears = duration;
        this.minimumYear = min;
        this.maximumYear = max;
        this.active = active;
    }
    public Long getId() { return programmeDegreeId; }
    public Programme getProgramme() { return programme; }
    public DegreeLevel getDegreeLevel() { return degreeLevel; }
    public Integer getDurationYears() { return durationYears; }
    public Integer getMinimumYear() { return minimumYear; }
    public Integer getMaximumYear() { return maximumYear; }
    public boolean isActive() { return active; }
}
