package com.uniconnect.profile.domain;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @DiscriminatorValue("STUDENT")
public class StudentProfile extends PersonalProfile {
    @Column(unique = true, length = 40) private String studentNumber;
    private Integer yearOfStudy;
    private Integer expectedGraduationYear;
    private Boolean projectAvailability;
    private Boolean mentorshipAvailability;
    protected StudentProfile() {}
    public StudentProfile(User user, LocalDateTime now) { super(user, now); }
    public void updateAcademicInfo(String number, int year, Integer graduationYear) {
        studentNumber = number; yearOfStudy = year; expectedGraduationYear = graduationYear;
    }
    public void setAvailability(boolean project, boolean mentorship, LocalDateTime now) {
        projectAvailability = project; mentorshipAvailability = mentorship; touch(now);
    }
    public String getStudentNumber() { return studentNumber; }
    public Integer getYearOfStudy() { return yearOfStudy; }
    public Integer getExpectedGraduationYear() { return expectedGraduationYear; }
    public Boolean getProjectAvailability() { return projectAvailability; }
    public Boolean getMentorshipAvailability() { return mentorshipAvailability; }
}
