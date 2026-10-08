package com.uniconnect.profile.mapper;

import com.uniconnect.connection.dto.ConnectionSummary;
import com.uniconnect.profile.domain.*;
import com.uniconnect.profile.dto.*;
import java.util.*;
import org.springframework.stereotype.Component;

@Component
public class MemberProfileMapper {
    private final ProfileMapper mapper;
    public MemberProfileMapper(ProfileMapper mapper) { this.mapper = mapper; }
    public MemberProfileResponse response(PersonalProfile p, boolean visible, ConnectionSummary relation, PersonalProfile own) {
        MemberProfileResponse.Details details = null;
        if (visible) {
            var skills = p.getSkills().stream().map(Skill::getName).sorted().toList();
            var interests = p.getInterests().stream().map(Interest::getName).sorted().toList();
            Set<String> ownSkills = new HashSet<>(), ownInterests = new HashSet<>();
            if (own != null) {
                own.getSkills().forEach(s -> ownSkills.add(s.getName()));
                own.getInterests().forEach(i -> ownInterests.add(i.getName()));
            }
            var student = p instanceof StudentProfile s ? new MemberProfileResponse.StudentDetails(s.getYearOfStudy(),
                    s.getExpectedGraduationYear(), s.getProjectAvailability(), s.getMentorshipAvailability()) : null;
            var alumni = p instanceof AlumniProfile a ? new ProfileResponse.AlumniDetails(a.getGraduationYear(), a.getCurrentCompany(),
                    a.getCurrentPosition(), a.getIndustry(), a.getCareerBackground(), a.getLinkedinUrl()) : null;
            details = new MemberProfileResponse.Details(mapper.degree(p.getProgrammeDegree()), p.getBio(), skills, interests,
                    skills.stream().filter(ownSkills::contains).toList(), interests.stream().filter(ownInterests::contains).toList(), student, alumni);
        }
        var programme = p.getProgrammeDegree().getProgramme();
        return new MemberProfileResponse(p.getUser().getUserId(), p.getUser().getFullName(), p.getUser().getPlatformRole(),
                p.getProfilePhotoUrl(), mapper.department(programme.getDepartment()), mapper.programme(programme), relation, visible, details);
    }
}
