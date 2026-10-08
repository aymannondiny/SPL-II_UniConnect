package com.uniconnect.profile.dto;

import com.uniconnect.profile.domain.DegreeLevel;
import java.util.List;

public record AcademicCatalogResponse(List<DepartmentOption> departments, List<ProgrammeOption> programmes, List<DegreeOption> degrees) {
    public record DepartmentOption(Long id, String name, String code) {}
    public record ProgrammeOption(Long id, Long departmentId, String name, String code) {}
    public record DegreeOption(Long id, Long programmeId, DegreeLevel degreeLevel, Integer durationYears, Integer minimumYear, Integer maximumYear, boolean active) {}
}
