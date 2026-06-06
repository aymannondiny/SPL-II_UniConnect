package com.spl2.uniconnect.integration.career;

import com.spl2.uniconnect.base.BaseIntegrationTest;
import com.spl2.uniconnect.domain.career.JobPosting;
import com.spl2.uniconnect.domain.career.JobType;
import com.spl2.uniconnect.domain.career.SavedJob;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.career.CreateJobRequest;
import com.spl2.uniconnect.repository.career.JobPostingRepository;
import com.spl2.uniconnect.repository.career.SavedJobRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

import java.time.LocalDate;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@DisplayName("Career Controller Integration Tests")
class CareerControllerTest extends BaseIntegrationTest {

    @Autowired
    private JobPostingRepository jobPostingRepository;

    @Autowired
    private SavedJobRepository savedJobRepository;

    private User alumniUser;
    private User studentUser;
    private JobPosting savedJobPosting;

    @BeforeEach
    void setUp() {
        alumniUser = createVerifiedAlumni("alumni@university.edu");
        studentUser = createVerifiedStudent("student@university.edu");

        savedJobPosting = jobPostingRepository.save(JobPosting.builder()
                .postedBy(alumniUser)
                .title("Software Engineer")
                .companyName("Google")
                .jobType(JobType.FULL_TIME)
                .location("Remote")
                .description("Great job opportunity at Google")
                .requirements("Java, Spring Boot, 3+ years experience")
                .applicationLink("https://google.com/jobs")
                .applicationDeadline(LocalDate.now().plusDays(30))
                .salaryRange("$100k-$150k")
                .build());
    }

    // =====================================================
    // POST JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("POST /api/career/jobs")
    class PostJobTests {

        @Test
        @DisplayName("Should create job successfully when alumni posts")
        void shouldCreateJobSuccessfully() throws Exception {
            CreateJobRequest request = CreateJobRequest.builder()
                    .title("Backend Developer")
                    .companyName("Amazon")
                    .jobType(JobType.FULL_TIME)
                    .location("New York")
                    .description("Backend role at Amazon")
                    .requirements("Java, AWS")
                    .applicationDeadline(LocalDate.now().plusDays(30))
                    .build();

            mockMvc.perform(post("/api/career/jobs")
                            .header("Authorization", bearerToken(alumniUser))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.title").value("Backend Developer"))
                    .andExpect(jsonPath("$.data.companyName").value("Amazon"))
                    .andExpect(jsonPath("$.data.jobType").value("FULL_TIME"));
        }

        @Test
        @DisplayName("Should return 403 when student tries to post a job")
        void shouldReturn403WhenStudentPostsJob() throws Exception {
            CreateJobRequest request = CreateJobRequest.builder()
                    .title("Backend Developer")
                    .companyName("Amazon")
                    .jobType(JobType.FULL_TIME)
                    .location("New York")
                    .description("Backend role at Amazon")
                    .requirements("Java, AWS")
                    .applicationDeadline(LocalDate.now().plusDays(30))
                    .build();

            mockMvc.perform(post("/api/career/jobs")
                            .header("Authorization", bearerToken(studentUser))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 403 when unauthenticated user posts a job")
        void shouldReturn401WhenUnauthenticated() throws Exception {
            CreateJobRequest request = CreateJobRequest.builder()
                    .title("Backend Developer")
                    .companyName("Amazon")
                    .jobType(JobType.FULL_TIME)
                    .location("New York")
                    .description("Backend role")
                    .requirements("Java")
                    .applicationDeadline(LocalDate.now().plusDays(30))
                    .build();

            mockMvc.perform(post("/api/career/jobs")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isForbidden()); // Spring Security returns 403 for unauthenticated
        }

        @Test
        @DisplayName("Should return 400 when required fields are missing")
        void shouldReturn400WhenFieldsMissing() throws Exception {
            CreateJobRequest request = CreateJobRequest.builder()
                    .title("")
                    .companyName("")
                    .build();

            mockMvc.perform(post("/api/career/jobs")
                            .header("Authorization", bearerToken(alumniUser))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
                    .andExpect(status().isBadRequest());
        }
    }

    // =====================================================
    // GET ALL JOBS TESTS
    // =====================================================
    @Nested
    @DisplayName("GET /api/career/jobs")
    class GetAllJobsTests {

        @Test
        @DisplayName("Should return all jobs when authenticated")
        void shouldReturnAllJobsWhenAuthenticated() throws Exception {
            mockMvc.perform(get("/api/career/jobs")
                            .header("Authorization", bearerToken(studentUser))
                            .param("page", "0")
                            .param("size", "10"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))))
                    .andExpect(jsonPath("$.data.content[0].title").value("Software Engineer"));
        }

        @Test
        @DisplayName("Should return 403 when not authenticated")
        void shouldReturn401WhenNotAuthenticated() throws Exception {
            mockMvc.perform(get("/api/career/jobs"))
                    .andExpect(status().isForbidden()); // Spring Security returns 403 for unauthenticated
        }

        @Test
        @DisplayName("Should return paginated results correctly")
        void shouldReturnPaginatedResults() throws Exception {
            mockMvc.perform(get("/api/career/jobs")
                            .header("Authorization", bearerToken(studentUser))
                            .param("page", "0")
                            .param("size", "5"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.pageSize").value(5))
                    .andExpect(jsonPath("$.data.pageNumber").value(0));
        }
    }

    // =====================================================
    // SEARCH JOBS TESTS
    // =====================================================
    @Nested
    @DisplayName("GET /api/career/jobs/search")
    class SearchJobsTests {

        @Test
        @DisplayName("Should return matching jobs when searching")
        void shouldReturnMatchingJobs() throws Exception {
            mockMvc.perform(get("/api/career/jobs/search")
                            .header("Authorization", bearerToken(studentUser))
                            .param("query", "Software"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))));
        }

        @Test
        @DisplayName("Should return empty list when no jobs match search")
        void shouldReturnEmptyWhenNoMatch() throws Exception {
            mockMvc.perform(get("/api/career/jobs/search")
                            .header("Authorization", bearerToken(studentUser))
                            .param("query", "XYZNONEXISTENT999"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.content", hasSize(0)));
        }

        @Test
        @DisplayName("Should return 403 when not authenticated")
        void shouldReturn401WhenNotAuthenticated() throws Exception {
            mockMvc.perform(get("/api/career/jobs/search")
                            .param("query", "Software"))
                    .andExpect(status().isForbidden()); // Spring Security returns 403 for unauthenticated
        }
    }

    // =====================================================
    // GET JOB BY ID TESTS
    // =====================================================
    @Nested
    @DisplayName("GET /api/career/jobs/{jobId}")
    class GetJobByIdTests {

        @Test
        @DisplayName("Should return job details when job exists")
        void shouldReturnJobDetails() throws Exception {
            mockMvc.perform(get("/api/career/jobs/{jobId}", savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.jobId").value(savedJobPosting.getJobId()))
                    .andExpect(jsonPath("$.data.title").value("Software Engineer"))
                    .andExpect(jsonPath("$.data.companyName").value("Google"));
        }

        @Test
        @DisplayName("Should return 404 when job does not exist")
        void shouldReturn404WhenJobNotFound() throws Exception {
            mockMvc.perform(get("/api/career/jobs/{jobId}", 99999L)
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isNotFound());
        }

        @Test
        @DisplayName("Should return 403 when not authenticated")
        void shouldReturn401WhenNotAuthenticated() throws Exception {
            mockMvc.perform(get("/api/career/jobs/{jobId}",
                            savedJobPosting.getJobId()))
                    .andExpect(status().isForbidden()); // Spring Security returns 403 for unauthenticated
        }
    }

    // =====================================================
    // SAVE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("POST /api/career/jobs/{jobId}/save")
    class SaveJobTests {

        @Test
        @DisplayName("Should save job successfully when student saves it")
        void shouldSaveJobSuccessfully() throws Exception {
            mockMvc.perform(post("/api/career/jobs/{jobId}/save",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.message").value("Job saved")); // ✅ fixed
        }

        @Test
        @DisplayName("Should return 400 when student tries to save same job twice")
        void shouldReturn400WhenJobAlreadySaved() throws Exception {
            savedJobRepository.save(SavedJob.builder()
                    .user(studentUser)
                    .jobPosting(savedJobPosting)
                    .build());

            mockMvc.perform(post("/api/career/jobs/{jobId}/save",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("Should return 403 when alumni tries to save a job")
        void shouldReturn403WhenAlumniSavesJob() throws Exception {
            mockMvc.perform(post("/api/career/jobs/{jobId}/save",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(alumniUser)))
                    .andExpect(status().isForbidden());
        }
    }

    // =====================================================
    // UNSAVE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("DELETE /api/career/jobs/{jobId}/save")
    class UnsaveJobTests {

        @Test
        @DisplayName("Should unsave job successfully")
        void shouldUnsaveJobSuccessfully() throws Exception {
            savedJobRepository.save(SavedJob.builder()
                    .user(studentUser)
                    .jobPosting(savedJobPosting)
                    .build());

            mockMvc.perform(delete("/api/career/jobs/{jobId}/save",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true));
        }

        @Test
        @DisplayName("Should return 404 when trying to unsave a job not saved")
        void shouldReturn404WhenJobNotSaved() throws Exception {
            mockMvc.perform(delete("/api/career/jobs/{jobId}/save",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isNotFound());
        }
    }

    // =====================================================
    // DELETE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("DELETE /api/career/jobs/{jobId}")
    class DeleteJobTests {

        @Test
        @DisplayName("Should delete job successfully when owner deletes it")
        void shouldDeleteJobSuccessfully() throws Exception {
            mockMvc.perform(delete("/api/career/jobs/{jobId}",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(alumniUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.message").value("Job deleted")); // ✅ fixed
        }

        @Test
        @DisplayName("Should return 403 when non-owner tries to delete job")
        void shouldReturn403WhenNotOwner() throws Exception {
            User anotherAlumni = createVerifiedAlumni("another@university.edu");

            mockMvc.perform(delete("/api/career/jobs/{jobId}",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(anotherAlumni)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 403 when student tries to delete job")
        void shouldReturn403WhenStudentDeletesJob() throws Exception {
            mockMvc.perform(delete("/api/career/jobs/{jobId}",
                            savedJobPosting.getJobId())
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isForbidden());
        }

        @Test
        @DisplayName("Should return 404 when job does not exist")
        void shouldReturn404WhenJobNotFound() throws Exception {
            mockMvc.perform(delete("/api/career/jobs/{jobId}", 99999L)
                            .header("Authorization", bearerToken(alumniUser)))
                    .andExpect(status().isNotFound());
        }
    }

    // =====================================================
    // FILTER TESTS
    // =====================================================
    @Nested
    @DisplayName("GET /api/career/jobs/companies and /locations")
    class FilterTests {

        @Test
        @DisplayName("Should return list of companies")
        void shouldReturnCompanies() throws Exception {
            mockMvc.perform(get("/api/career/jobs/companies")
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data", hasItem("Google")));
        }

        @Test
        @DisplayName("Should return list of locations")
        void shouldReturnLocations() throws Exception {
            mockMvc.perform(get("/api/career/jobs/locations")
                            .header("Authorization", bearerToken(studentUser)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data", hasItem("Remote")));
        }
    }
}