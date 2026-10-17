package com.uniconnect.profile.service;

import com.uniconnect.authentication.service.ProfileAccountService;
import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.mapper.ProfileMapper;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.dto.AcademicCatalogResponse.*;
import com.uniconnect.profile.repository.*;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.util.Comparator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class AcademicCatalogService {
    private final ProfileAccountService accounts;
    private final DepartmentRepository departments;
    private final ProgrammeRepository programmes;
    private final ProgrammeDegreeRepository degrees;
    private final PersonalProfileRepository profiles;
    private final ProfileValidation validation;
    private final ProfileMapper mapper;
    public AcademicCatalogService(ProfileAccountService accounts, DepartmentRepository departments,
            ProgrammeRepository programmes, ProgrammeDegreeRepository degrees, PersonalProfileRepository profiles,
            ProfileValidation validation, ProfileMapper mapper) {
        this.accounts = accounts; this.departments = departments; this.programmes = programmes;
        this.degrees = degrees; this.profiles = profiles; this.validation = validation; this.mapper = mapper;
    }
    private void requireAdmin(SessionPrincipal actor) {
        if (accounts.lockActiveAccount(actor).getPlatformRole() != PlatformRole.SYSTEM_ADMIN)
            throw new ForbiddenException("Only system administrators may manage academic options.");
    }
    public AcademicCatalogResponse list(SessionPrincipal actor, boolean includeInactive) {
        if (includeInactive) requireAdmin(actor); else accounts.lockActiveAccount(actor);
        return new AcademicCatalogResponse(
                departments.findAll().stream().sorted(Comparator.comparing(Department::getCode)).map(mapper::department).toList(),
                programmes.findAll().stream().sorted(Comparator.comparing(Programme::getCode)).map(mapper::programme).toList(),
                degrees.findAll().stream().filter(d -> includeInactive || d.isActive()).sorted(Comparator.comparing(ProgrammeDegree::getId)).map(mapper::degree).toList());
    }
    public DepartmentOption createDepartment(SessionPrincipal actor, DepartmentRequest request) {
        requireAdmin(actor); validation.validate(request);
        return mapper.department(departments.saveAndFlush(new Department(validation.required(request.name()), validation.code(request.code()))));
    }
    public DepartmentOption updateDepartment(SessionPrincipal actor, Long id, DepartmentRequest request) {
        requireAdmin(actor); validation.validate(request);
        var department = departments.lockById(id).orElseThrow(() -> new ResourceNotFoundException("Department", id));
        department.rename(validation.required(request.name()), validation.code(request.code()));
        departments.flush();
        return mapper.department(department);
    }
    public ProgrammeOption createProgramme(SessionPrincipal actor, ProgrammeRequest request) {
        requireAdmin(actor); validation.validate(request);
        var department = departments.findById(request.departmentId()).orElseThrow(() -> new ResourceNotFoundException("Department", request.departmentId()));
        return mapper.programme(programmes.saveAndFlush(new Programme(validation.required(request.name()), validation.code(request.code()), department)));
    }
    public ProgrammeOption updateProgramme(SessionPrincipal actor, Long id, ProgrammeRequest request) {
        requireAdmin(actor); validation.validate(request);
        var programme = programmes.lockById(id).orElseThrow(() -> new ResourceNotFoundException("Programme", id));
        if (!programme.getDepartment().getId().equals(request.departmentId()))
            throw new ConflictException("ACADEMIC_PARENT_IMMUTABLE", "Create a new programme instead of changing its department.");
        programme.rename(validation.required(request.name()), validation.code(request.code()));
        programmes.flush();
        return mapper.programme(programme);
    }
    public DegreeOption createDegree(SessionPrincipal actor, DegreeRequest request) {
        requireAdmin(actor); validateDegree(request);
        var programme = programmes.findById(request.programmeId()).orElseThrow(() -> new ResourceNotFoundException("Programme", request.programmeId()));
        return mapper.degree(degrees.saveAndFlush(new ProgrammeDegree(programme, request.degreeLevel(), request.durationYears(), request.minimumYear(), request.maximumYear(), request.active())));
    }
    public DegreeOption updateDegree(SessionPrincipal actor, Long id, DegreeRequest request) {
        requireAdmin(actor); validateDegree(request);
        var degree = degrees.lockById(id).orElseThrow(() -> new ResourceNotFoundException("Programme degree", id));
        if (!degree.getProgramme().getId().equals(request.programmeId()) || degree.getDegreeLevel() != request.degreeLevel())
            throw new ConflictException("ACADEMIC_PARENT_IMMUTABLE", "Create a new degree option instead of changing its programme or level.");
        boolean changedRange = !degree.getDurationYears().equals(request.durationYears())
                || !degree.getMinimumYear().equals(request.minimumYear()) || !degree.getMaximumYear().equals(request.maximumYear());
        if (changedRange && profiles.existsByProgrammeDegreeProgrammeDegreeId(id))
            throw new ConflictException("ACADEMIC_OPTION_IN_USE", "Study-year rules cannot change while a profile uses this option.");
        degree.revise(request.durationYears(), request.minimumYear(), request.maximumYear(), request.active());
        degrees.flush();
        return mapper.degree(degree);
    }
    private void validateDegree(DegreeRequest request) {
        validation.validate(request);
        if (request.minimumYear() > request.maximumYear())
            throw new BadRequestException("INVALID_STUDY_YEAR_RANGE", "Minimum study year cannot exceed maximum study year.");
    }
}
