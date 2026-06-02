package com.spl2.uniconnect.integration;

import com.spl2.uniconnect.base.BaseIntegrationTest;
import com.spl2.uniconnect.domain.academic.DegreeLevel;
import com.spl2.uniconnect.domain.academic.Department;
import com.spl2.uniconnect.domain.academic.Programme;
import com.spl2.uniconnect.domain.user.*;
import com.spl2.uniconnect.dto.request.user.UpdateAdminProfileRequest;
import com.spl2.uniconnect.dto.request.user.UpdateAlumniProfileRequest;
import com.spl2.uniconnect.dto.request.user.UpdateClubProfileRequest;
import com.spl2.uniconnect.dto.request.user.UpdateStudentProfileRequest;
import com.spl2.uniconnect.repository.academic.DegreeLevelRepository;
import com.spl2.uniconnect.repository.academic.DepartmentRepository;
import com.spl2.uniconnect.repository.academic.ProgrammeRepository;
import com.spl2.uniconnect.repository.user.AdminProfileRepository;
import com.spl2.uniconnect.repository.user.AlumniProfileRepository;
import com.spl2.uniconnect.repository.user.ClubProfileRepository;
import com.spl2.uniconnect.repository.user.StudentProfileRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("Profile Update Operations - Integration Tests")
class ProfileUpdateIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private StudentProfileRepository studentProfileRepository;

    @Autowired
    private AlumniProfileRepository alumniProfileRepository;

    @Autowired
    private ClubProfileRepository clubProfileRepository;

    @Autowired
    private AdminProfileRepository adminProfileRepository;

    @Autowired
    private ProgrammeRepository programmeRepository;

    @Autowired
    private DegreeLevelRepository degreeLevelRepository;

    @Autowired
    private DepartmentRepository departmentRepository;

    private Programme programme;
    private DegreeLevel degreeLevel;
    private Department department;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        studentProfileRepository.deleteAll();
        alumniProfileRepository.deleteAll();
        clubProfileRepository.deleteAll();
        adminProfileRepository.deleteAll();

        degreeLevel = degreeLevelRepository.findById(1L)
                .orElseGet(() -> degreeLevelRepository.save(
                        DegreeLevel.builder()
                                .degreeName("Undergraduate")
                                .minYears(4)
                                .maxYears(4)
                                .description("Bachelor's degree")
                                .build()
                ));

        department = departmentRepository.findById(1L)
                .orElseGet(() -> departmentRepository.save(
                        Department.builder()
                                .departmentName("Computer Science")
                                .departmentCode("CS")
                                .description("Computer Science Department")
                                .build()
                ));

        programme = programmeRepository.findById(1L)
                .orElseGet(() -> programmeRepository.save(
                        Programme.builder()
                                .department(department)
                                .programmeName("Computer Science")
                                .programmeCode("CS")
                                .description("BSc in Computer Science")
                                .build()
                ));
    }

    // ============================================
    // STUDENT PROFILE UPDATE TESTS
    // ============================================

    @Nested
    @DisplayName("Student Profile Update - PUT /api/profiles/students/{userId}")
    class StudentProfileUpdate {

        @Test
        @DisplayName("Should update own student profile successfully")
        void shouldUpdateOwnProfile() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .bio("Old bio")
                    .lookingForTeammates(false)
                    .openToMentorship(false)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(3);
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());
            request.setBio("Updated bio - now in year 3!");
            request.setLookingForTeammates(true);
            request.setOpenToMentorship(true);

            // When & Then
            mockMvc.perform(put("/api/profiles/students/" + student.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.yearOfStudy").value(3))
                    .andExpect(jsonPath("$.data.bio").value("Updated bio - now in year 3!"))
                    .andExpect(jsonPath("$.data.lookingForTeammates").value(true))
                    .andExpect(jsonPath("$.data.openToMentorship").value(true));

            // Verify database updated
            StudentProfile updated = studentProfileRepository.findById(student.getUserId()).get();
            assertThat(updated.getYearOfStudy()).isEqualTo(3);
            assertThat(updated.getBio()).isEqualTo("Updated bio - now in year 3!");
        }

        @Test
        @DisplayName("Should validate required fields")
        void shouldValidateRequiredFields() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            // Missing yearOfStudy
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());

            // When & Then
            mockMvc.perform(put("/api/profiles/students/" + student.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should validate year of study range (1-7)")
        void shouldValidateYearOfStudyRange() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            // Invalid year (8 > max 7)
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(8);
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());

            // When & Then
            mockMvc.perform(put("/api/profiles/students/" + student.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.error").value("Validation Failed"));
        }

        @Test
        @DisplayName("Should update partial fields")
        void shouldUpdatePartialFields() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .bio("Original bio")
                    .lookingForTeammates(false)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            // Only update lookingForTeammates
            UpdateStudentProfileRequest request = new UpdateStudentProfileRequest();
            request.setYearOfStudy(2); // Same as before
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());
            request.setLookingForTeammates(true); // Changed

            // When & Then
            mockMvc.perform(put("/api/profiles/students/" + student.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.lookingForTeammates").value(true))
                    .andExpect(jsonPath("$.data.bio").value("Original bio")); // Unchanged
        }
    }

    // ============================================
    // ALUMNI PROFILE UPDATE TESTS
    // ============================================

    @Nested
    @DisplayName("Alumni Profile Update - PUT /api/profiles/alumni/{userId}")
    class AlumniProfileUpdate {

        @Test
        @DisplayName("Should update own alumni profile successfully")
        void shouldUpdateOwnProfile() throws Exception {
            // Given
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .currentCompany("Old Company")
                    .currentPosition("Junior Developer")
                    .build();
            alumniProfileRepository.save(profile);

            String token = generateTokenForUser(alumni);

            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setGraduationYear(2020);
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());
            request.setCurrentCompany("Google");
            request.setCurrentPosition("Senior Software Engineer");
            request.setIndustry("Technology");
            request.setCareerBackground("Moved from startup to FAANG");

            // When & Then
            mockMvc.perform(put("/api/profiles/alumni/" + alumni.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.currentCompany").value("Google"))
                    .andExpect(jsonPath("$.data.currentPosition").value("Senior Software Engineer"))
                    .andExpect(jsonPath("$.data.industry").value("Technology"));

            // Verify database
            AlumniProfile updated = alumniProfileRepository.findById(alumni.getUserId()).get();
            assertThat(updated.getCurrentCompany()).isEqualTo("Google");
            assertThat(updated.getCareerBackground()).isEqualTo("Moved from startup to FAANG");
        }

        @Test
        @DisplayName("Should validate required fields")
        void shouldValidateRequiredFields() throws Exception {
            // Given
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .build();
            alumniProfileRepository.save(profile);

            String token = generateTokenForUser(alumni);

            // Missing graduationYear
            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());

            // When & Then
            mockMvc.perform(put("/api/profiles/alumni/" + alumni.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should update career information")
        void shouldUpdateCareerInformation() throws Exception {
            // Given
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2019)
                    .currentCompany("Startup Inc")
                    .build();
            alumniProfileRepository.save(profile);

            String token = generateTokenForUser(alumni);

            UpdateAlumniProfileRequest request = new UpdateAlumniProfileRequest();
            request.setGraduationYear(2019);
            request.setProgrammeId(programme.getProgrammeId());
            request.setDegreeLevelId(degreeLevel.getDegreeLevelId());
            request.setCurrentCompany("Microsoft");
            request.setCurrentPosition("Cloud Architect");
            request.setIndustry("Cloud Computing");
            request.setLinkedinUrl("https://linkedin.com/in/johndoe");

            // When & Then
            mockMvc.perform(put("/api/profiles/alumni/" + alumni.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.currentCompany").value("Microsoft"))
                    .andExpect(jsonPath("$.data.currentPosition").value("Cloud Architect"))
                    .andExpect(jsonPath("$.data.linkedinUrl").value("https://linkedin.com/in/johndoe"));
        }
    }

    // ============================================
    // CLUB PROFILE UPDATE TESTS
    // ============================================

    @Nested
    @DisplayName("Club Profile Update - PUT /api/profiles/clubs/{userId}")
    class ClubProfileUpdate {

        @Test
        @DisplayName("Should update own club profile successfully")
        void shouldUpdateOwnProfile() throws Exception {
            // Given
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Old Club Name")
                    .description("Old description")
                    .category("Academic")
                    .foundedYear(2020)
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("Tech Innovators Club");
            request.setDescription("A club dedicated to technological innovation and learning");
            request.setCategory("Tech");
            request.setFoundedYear(2018);
            request.setMeetingSchedule("Every Friday 4PM");
            request.setContactEmail("contact@techclub.iut.edu");

            // When & Then
            mockMvc.perform(put("/api/profiles/clubs/" + clubUser.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.clubName").value("Tech Innovators Club"))
                    .andExpect(jsonPath("$.data.category").value("Tech"))
                    .andExpect(jsonPath("$.data.meetingSchedule").value("Every Friday 4PM"));

            // Verify database
            ClubProfile updated = clubProfileRepository.findById(clubUser.getUserId()).get();
            assertThat(updated.getClubName()).isEqualTo("Tech Innovators Club");
            assertThat(updated.getFoundedYear()).isEqualTo(2018);
        }

        @Test
        @DisplayName("Should validate required fields")
        void shouldValidateRequiredFields() throws Exception {
            // Given
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Tech Club")
                    .description("A tech club")
                    .category("Tech")
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            // Missing clubName
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setDescription("Updated description");
            request.setCategory("Tech");

            // When & Then
            mockMvc.perform(put("/api/profiles/clubs/" + clubUser.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should validate category pattern")
        void shouldValidateCategoryPattern() throws Exception {
            // Given
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Tech Club")
                    .description("A tech club")
                    .category("Tech")
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            // Invalid category
            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("Tech Club");
            request.setDescription("A tech club description");
            request.setCategory("InvalidCategory");

            // When & Then
            mockMvc.perform(put("/api/profiles/clubs/" + clubUser.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.error").value("Validation Failed"));
        }

        @Test
        @DisplayName("Should update contact information")
        void shouldUpdateContactInformation() throws Exception {
            // Given
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Sports Club")
                    .description("Sports and fitness")
                    .category("Sports")
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            UpdateClubProfileRequest request = new UpdateClubProfileRequest();
            request.setClubName("Sports Club");
            request.setDescription("Sports and fitness activities for all students");
            request.setCategory("Sports");
            request.setContactEmail("sports@iut.edu");
            request.setWebsiteUrl("https://sportsclub.iut.edu");
            request.setMeetingSchedule("Tuesdays and Thursdays 5PM");

            // When & Then
            mockMvc.perform(put("/api/profiles/clubs/" + clubUser.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.contactEmail").value("sports@iut.edu"))
                    .andExpect(jsonPath("$.data.websiteUrl").value("https://sportsclub.iut.edu"));
        }
    }

    // ============================================
    // ADMIN PROFILE UPDATE TESTS
    // ============================================

    @Nested
    @DisplayName("Admin Profile Update - PUT /api/profiles/admins/{userId}")
    class AdminProfileUpdate {

        @Test
        @DisplayName("Should update own admin profile successfully")
        void shouldUpdateOwnProfile() throws Exception {
            // Given
            User admin = createVerifiedAdmin("admin@iut-dhaka.edu");
            AdminProfile profile = AdminProfile.builder()
                    .user(admin)
                    .adminRole("Moderator")
                    .build();
            adminProfileRepository.save(profile);

            String token = generateTokenForUser(admin);

            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setAdminRole("Senior Moderator");
            request.setProfilePhoto("https://example.com/admin-photo.jpg");

            // When & Then
            mockMvc.perform(put("/api/profiles/admins/" + admin.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.adminRole").value("Senior Moderator"));

            // Verify database
            AdminProfile updated = adminProfileRepository.findById(admin.getUserId()).get();
            assertThat(updated.getAdminRole()).isEqualTo("Senior Moderator");
        }

        @Test
        @DisplayName("Should validate required admin role")
        void shouldValidateRequiredRole() throws Exception {
            // Given
            User admin = createVerifiedAdmin("admin@iut-dhaka.edu");
            AdminProfile profile = AdminProfile.builder()
                    .user(admin)
                    .adminRole("Admin")
                    .build();
            adminProfileRepository.save(profile);

            String token = generateTokenForUser(admin);

            // Missing adminRole
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setProfilePhoto("photo.jpg");

            // When & Then
            mockMvc.perform(put("/api/profiles/admins/" + admin.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should validate admin role length")
        void shouldValidateRoleLength() throws Exception {
            // Given
            User admin = createVerifiedAdmin("admin@iut-dhaka.edu");
            AdminProfile profile = AdminProfile.builder()
                    .user(admin)
                    .adminRole("Admin")
                    .build();
            adminProfileRepository.save(profile);

            String token = generateTokenForUser(admin);

            // Too short (< 3 chars)
            UpdateAdminProfileRequest request = new UpdateAdminProfileRequest();
            request.setAdminRole("AB");

            // When & Then
            mockMvc.perform(put("/api/profiles/admins/" + admin.getUserId())
                    .header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.error").value("Validation Failed"));
        }
    }
}
