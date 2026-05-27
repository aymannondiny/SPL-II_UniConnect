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

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("Profile Controller Integration Tests")
class ProfileControllerTest extends BaseIntegrationTest {

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

        // Create academic structure
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
    // STUDENT PROFILE TESTS
    // ============================================

    @Nested
    @DisplayName("Student Profile - GET")
    class StudentProfileGet {

        @Test
        @DisplayName("Should get student profile by user ID")
        void shouldGetStudentProfileByUserId() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .bio("Software engineering student")
                    .lookingForTeammates(true)
                    .openToMentorship(false)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            mockMvc.perform(get("/api/profiles/students/" + student.getUserId())
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.yearOfStudy").value(2))
                    .andExpect(jsonPath("$.data.lookingForTeammates").value(true));
        }

        @Test
        @DisplayName("Should get my student profile")
        void shouldGetMyStudentProfile() throws Exception {
            // Given
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(3)
                    .bio("Year 3 student")
                    .lookingForTeammates(false)
                    .openToMentorship(true)
                    .build();
            studentProfileRepository.save(profile);

            String token = generateTokenForUser(student);

            mockMvc.perform(get("/api/profiles/students/me")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.openToMentorship").value(true));
        }
    }

    @Nested
    @DisplayName("Student Profile - Search")
    class StudentProfileSearch {

        @Test
        @DisplayName("Should get students looking for teammates")
        void shouldGetStudentsLookingForTeammates() throws Exception {
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .lookingForTeammates(true)
                    .build();
            studentProfileRepository.save(profile);

            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/students/teammates")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should filter students by year")
        void shouldFilterStudentsByYear() throws Exception {
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(3)
                    .build();
            studentProfileRepository.save(profile);

            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/students/year/3")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should get students open to mentorship")
        void shouldGetStudentsOpenToMentorship() throws Exception {
            User student = createVerifiedStudent("student@iut-dhaka.edu");
            StudentProfile profile = StudentProfile.builder()
                    .user(student)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .yearOfStudy(2)
                    .openToMentorship(true)
                    .build();
            studentProfileRepository.save(profile);

            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/students/mentorship")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }
    }

    // ============================================
    // ALUMNI PROFILE TESTS
    // ============================================

    @Nested
    @DisplayName("Alumni Profile - GET")
    class AlumniProfileGet {

        @Test
        @DisplayName("Should get alumni profile by user ID")
        void shouldGetAlumniProfileByUserId() throws Exception {
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .currentCompany("Google")
                    .currentPosition("Software Engineer")
                    .industry("Technology")
                    .build();
            alumniProfileRepository.save(profile);

            String token = generateTokenForUser(alumni);

            mockMvc.perform(get("/api/profiles/alumni/" + alumni.getUserId())
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.graduationYear").value(2020))
                    .andExpect(jsonPath("$.data.currentCompany").value("Google"));
        }

        @Test
        @DisplayName("Should get my alumni profile")
        void shouldGetMyAlumniProfile() throws Exception {
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2019)
                    .currentCompany("Microsoft")
                    .build();
            alumniProfileRepository.save(profile);

            String token = generateTokenForUser(alumni);

            mockMvc.perform(get("/api/profiles/alumni/me")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.currentCompany").value("Microsoft"));
        }
    }

    @Nested
    @DisplayName("Alumni Profile - Search")
    class AlumniProfileSearch {

        @Test
        @DisplayName("Should get alumni by graduation year")
        void shouldGetAlumniByYear() throws Exception {
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .build();
            alumniProfileRepository.save(profile);

            User viewer = createVerifiedAlumni("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/alumni/year/2020")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should get alumni by year range")
        void shouldGetAlumniByYearRange() throws Exception {
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .build();
            alumniProfileRepository.save(profile);

            User viewer = createVerifiedAlumni("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/alumni/year-range")
                    .param("start", "2018")
                    .param("end", "2022")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should search alumni by company")
        void shouldSearchAlumniByCompany() throws Exception {
            User alumni = createVerifiedAlumni("alumni@iut-dhaka.edu");
            AlumniProfile profile = AlumniProfile.builder()
                    .user(alumni)
                    .programme(programme)
                    .degreeLevel(degreeLevel)
                    .graduationYear(2020)
                    .currentCompany("Google")
                    .build();
            alumniProfileRepository.save(profile);

            User viewer = createVerifiedAlumni("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/alumni/company")
                    .param("query", "Google")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }
    }

    // ============================================
    // CLUB PROFILE TESTS
    // ============================================

    @Nested
    @DisplayName("Club Profile - GET")
    class ClubProfileGet {

        @Test
        @DisplayName("Should get club profile by user ID")
        void shouldGetClubProfileByUserId() throws Exception {
            User clubUser = createVerifiedClub("techclub@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Tech Club")
                    .description("A club for tech enthusiasts")
                    .category("Tech")
                    .foundedYear(2018)
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            mockMvc.perform(get("/api/profiles/clubs/" + clubUser.getUserId())
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.clubName").value("Tech Club"));
        }

        @Test
        @DisplayName("Should get my club profile")
        void shouldGetMyClubProfile() throws Exception {
            User clubUser = createVerifiedClub("roboticsclub@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Robotics Club")
                    .description("Build amazing robots")
                    .category("Tech")
                    .foundedYear(2015)
                    .build();
            clubProfileRepository.save(profile);

            String token = generateTokenForUser(clubUser);

            mockMvc.perform(get("/api/profiles/clubs/me")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.clubName").value("Robotics Club"));
        }
    }

    @Nested
    @DisplayName("Club Profile - Search")
    class ClubProfileSearch {

        @Test
        @DisplayName("Should search clubs by name")
        void shouldSearchClubsByName() throws Exception {
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Photography Club")
                    .description("Photography enthusiasts")
                    .category("Arts")
                    .build();
            clubProfileRepository.save(profile);

            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/clubs/search")
                    .param("query", "Photography")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should filter clubs by category")
        void shouldFilterClubsByCategory() throws Exception {
            User clubUser = createVerifiedClub("club@iut-dhaka.edu");
            ClubProfile profile = ClubProfile.builder()
                    .user(clubUser)
                    .clubName("Sports Club")
                    .description("Sports activities")
                    .category("Sports")
                    .build();
            clubProfileRepository.save(profile);

            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/clubs/category/Sports")
                    .param("page", "0")
                    .param("size", "10")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should get all club categories")
        void shouldGetAllCategories() throws Exception {
            User viewer = createVerifiedStudent("viewer@iut-dhaka.edu");
            String token = generateTokenForUser(viewer);

            mockMvc.perform(get("/api/profiles/clubs/categories")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }
    }

    // ============================================
    // ADMIN PROFILE TESTS
    // ============================================

    @Nested
    @DisplayName("Admin Profile - GET")
    class AdminProfileGet {

        @Test
        @DisplayName("Should get admin profile")
        void shouldGetAdminProfile() throws Exception {
            User admin = createVerifiedAdmin("admin@iut-dhaka.edu");
            AdminProfile profile = AdminProfile.builder()
                    .user(admin)
                    .adminRole("Content Moderator")
                    .build();
            adminProfileRepository.save(profile);

            String token = generateTokenForUser(admin);

            mockMvc.perform(get("/api/profiles/admins/" + admin.getUserId())
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.adminRole").value("Content Moderator"));
        }

        @Test
        @DisplayName("Should get all admins")
        void shouldGetAllAdmins() throws Exception {
            User admin = createVerifiedAdmin("admin@iut-dhaka.edu");
            AdminProfile profile = AdminProfile.builder()
                    .user(admin)
                    .adminRole("Super Admin")
                    .build();
            adminProfileRepository.save(profile);

            String token = generateTokenForUser(admin);

            mockMvc.perform(get("/api/profiles/admins")
                    .header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }
    }
}
