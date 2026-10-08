package com.uniconnect.profile.mapper;

import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.dto.*;
import com.uniconnect.profile.dto.AcademicCatalogResponse.*;
import org.springframework.stereotype.Component;

@Component
public class ProfileMapper {
    public DepartmentOption department(Department e) { return new DepartmentOption(e.getId(), e.getName(), e.getCode()); }
    public ProgrammeOption programme(Programme e) { return new ProgrammeOption(e.getId(), e.getDepartment().getId(), e.getName(), e.getCode()); }
    public DegreeOption degree(ProgrammeDegree e) { return new DegreeOption(e.getId(), e.getProgramme().getId(), e.getDegreeLevel(), e.getDurationYears(), e.getMinimumYear(), e.getMaximumYear(), e.isActive()); }
    public ProfileResponse profile(PersonalProfile e) {
        var degree = e.getProgrammeDegree();
        ProfileResponse.StudentDetails student = e instanceof StudentProfile s
                ? new ProfileResponse.StudentDetails(s.getStudentNumber(), s.getYearOfStudy(), s.getExpectedGraduationYear(), s.getProjectAvailability(), s.getMentorshipAvailability()) : null;
        ProfileResponse.AlumniDetails alumni = e instanceof AlumniProfile a
                ? new ProfileResponse.AlumniDetails(a.getGraduationYear(), a.getCurrentCompany(), a.getCurrentPosition(), a.getIndustry(), a.getCareerBackground(), a.getLinkedinUrl()) : null;
        return new ProfileResponse(e.getId(), e.getUser().getUserId(), e.getUser().getFullName(), e.getUser().getPlatformRole(),
                department(degree.getProgramme().getDepartment()), programme(degree.getProgramme()), degree(degree),
                e.getBio(), e.getProfilePhotoUrl(), e.getSkills().stream().map(Skill::getName).sorted().toList(),
                e.getInterests().stream().map(Interest::getName).sorted().toList(), student, alumni, e.getCreatedAt(), e.getUpdatedAt());
    }
}
