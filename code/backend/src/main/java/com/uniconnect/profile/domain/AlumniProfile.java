package com.uniconnect.profile.domain;

import com.uniconnect.authentication.domain.User;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity @DiscriminatorValue("ALUMNI")
public class AlumniProfile extends PersonalProfile {
    private Integer graduationYear;
    @Column(length = 150) private String currentCompany;
    @Column(length = 150) private String currentPosition;
    @Column(length = 100) private String industry;
    @Column(length = 2000) private String careerBackground;
    @Column(length = 2048) private String linkedinUrl;
    protected AlumniProfile() {}
    public AlumniProfile(User user, LocalDateTime now) { super(user, now); }
    public void updateCareerInfo(int year, String company, String position, String industry, String background, String linkedin) {
        graduationYear = year; currentCompany = company; currentPosition = position;
        this.industry = industry; careerBackground = background; linkedinUrl = linkedin;
    }
    public Integer getGraduationYear() { return graduationYear; }
    public String getCurrentCompany() { return currentCompany; }
    public String getCurrentPosition() { return currentPosition; }
    public String getIndustry() { return industry; }
    public String getCareerBackground() { return careerBackground; }
    public String getLinkedinUrl() { return linkedinUrl; }
}
