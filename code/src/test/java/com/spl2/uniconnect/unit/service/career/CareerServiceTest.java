package com.spl2.uniconnect.unit.service.career;

import com.spl2.uniconnect.base.BaseUnitTest;
import com.spl2.uniconnect.domain.career.JobPosting;
import com.spl2.uniconnect.domain.career.JobType;
import com.spl2.uniconnect.domain.career.SavedJob;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import com.spl2.uniconnect.dto.request.career.CreateJobRequest;
import com.spl2.uniconnect.dto.response.career.JobPostingResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.career.JobPostingRepository;
import com.spl2.uniconnect.repository.career.SavedJobRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import com.spl2.uniconnect.service.career.CareerService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@DisplayName("CareerService Unit Tests")
class CareerServiceTest extends BaseUnitTest {

    @Mock
    private JobPostingRepository jobPostingRepository;

    @Mock
    private SavedJobRepository savedJobRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private CareerService careerService;

    private User alumniUser;
    private User studentUser;
    private JobPosting jobPosting;
    private CreateJobRequest createJobRequest;

    @BeforeEach
    void setUp() {
        alumniUser = User.builder()
                .userId(1L)
                .email("alumni@university.edu")
                .fullName("Alumni User")
                .role(UserRole.ALUMNI)
                .emailVerified(true)
                .build();

        studentUser = User.builder()
                .userId(2L)
                .email("student@university.edu")
                .fullName("Student User")
                .role(UserRole.STUDENT)
                .emailVerified(true)
                .build();

        jobPosting = JobPosting.builder()
                .jobId(1L)
                .postedBy(alumniUser)
                .title("Software Engineer")
                .companyName("Google")
                .jobType(JobType.FULL_TIME)
                .location("Remote")
                .description("Great job opportunity")
                .requirements("Java, Spring Boot")
                .applicationLink("https://google.com/jobs")
                .applicationDeadline(LocalDate.now().plusDays(30))
                .salaryRange("$100k-$150k")
                .createdAt(LocalDateTime.now())
                .build();

        createJobRequest = CreateJobRequest.builder()
                .title("Software Engineer")
                .companyName("Google")
                .jobType(JobType.FULL_TIME)
                .location("Remote")
                .description("Great job opportunity")
                .requirements("Java, Spring Boot")
                .applicationLink("https://google.com/jobs")
                .applicationDeadline(LocalDate.now().plusDays(30))
                .salaryRange("$100k-$150k")
                .build();
    }

    // =====================================================
    // CREATE JOB POSTING TESTS
    // =====================================================
    @Nested
    @DisplayName("createJobPosting()")
    class CreateJobPostingTests {

        @Test
        @DisplayName("Should create job posting successfully when alumni posts a job")
        void shouldCreateJobPostingSuccessfully() {
            when(userRepository.findById(1L)).thenReturn(Optional.of(alumniUser));
            when(jobPostingRepository.save(any(JobPosting.class))).thenReturn(jobPosting);
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            JobPostingResponse response = careerService.createJobPosting(createJobRequest, 1L);

            assertThat(response).isNotNull();
            assertThat(response.getTitle()).isEqualTo("Software Engineer");
            assertThat(response.getCompanyName()).isEqualTo("Google");
            assertThat(response.getJobType()).isEqualTo(JobType.FULL_TIME);
            assertThat(response.getLocation()).isEqualTo("Remote");
            verify(jobPostingRepository, times(1)).save(any(JobPosting.class));
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user not found")
        void shouldThrowExceptionWhenUserNotFound() {
            when(userRepository.findById(99L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.createJobPosting(createJobRequest, 99L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("User not found");

            verify(jobPostingRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should save job with all required fields correctly")
        void shouldSaveJobWithAllFields() {
            when(userRepository.findById(1L)).thenReturn(Optional.of(alumniUser));
            when(jobPostingRepository.save(any(JobPosting.class))).thenReturn(jobPosting);
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            JobPostingResponse response = careerService.createJobPosting(createJobRequest, 1L);

            assertThat(response.getPostedByUserId()).isEqualTo(1L);
            assertThat(response.getPostedByName()).isEqualTo("Alumni User");
            assertThat(response.getSalaryRange()).isEqualTo("$100k-$150k");
        }
    }

    // =====================================================
    // GET ALL JOBS TESTS
    // =====================================================
    @Nested
    @DisplayName("getAllJobs()")
    class GetAllJobsTests {

        @Test
        @DisplayName("Should return paginated list of all jobs")
        void shouldReturnAllJobs() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<JobPosting> jobPage = new PageImpl<>(List.of(jobPosting));

            when(jobPostingRepository.findAllByOrderByCreatedAtDesc(pageable))
                    .thenReturn(jobPage);
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            Page<JobPostingResponse> result = careerService.getAllJobs(pageable, 2L);

            assertThat(result).isNotNull();
            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getTitle()).isEqualTo("Software Engineer");
        }

        @Test
        @DisplayName("Should return empty page when no jobs exist")
        void shouldReturnEmptyPageWhenNoJobs() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<JobPosting> emptyPage = new PageImpl<>(List.of());

            when(jobPostingRepository.findAllByOrderByCreatedAtDesc(pageable))
                    .thenReturn(emptyPage);

            Page<JobPostingResponse> result = careerService.getAllJobs(pageable, 2L);

            assertThat(result.getContent()).isEmpty();
            assertThat(result.getTotalElements()).isEqualTo(0);
        }
    }

    // =====================================================
    // SEARCH JOBS TESTS
    // =====================================================
    @Nested
    @DisplayName("searchJobs()")
    class SearchJobsTests {

        @Test
        @DisplayName("Should return matching jobs when searching by title")
        void shouldReturnMatchingJobs() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<JobPosting> jobPage = new PageImpl<>(List.of(jobPosting));

            when(jobPostingRepository.searchJobs("Software", pageable)).thenReturn(jobPage);
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            Page<JobPostingResponse> result = careerService.searchJobs("Software", pageable, 2L);

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getTitle()).isEqualTo("Software Engineer");
        }

        @Test
        @DisplayName("Should return empty page when no jobs match search query")
        void shouldReturnEmptyPageWhenNoMatch() {
            Pageable pageable = PageRequest.of(0, 10);
            when(jobPostingRepository.searchJobs("XYZ123", pageable))
                    .thenReturn(new PageImpl<>(List.of()));

            Page<JobPostingResponse> result = careerService.searchJobs("XYZ123", pageable, 2L);

            assertThat(result.getContent()).isEmpty();
        }
    }

    // =====================================================
    // GET JOB BY ID TESTS
    // =====================================================
    @Nested
    @DisplayName("getJobById()")
    class GetJobByIdTests {

        @Test
        @DisplayName("Should return job details when job exists")
        void shouldReturnJobWhenExists() {
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.of(jobPosting));
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            JobPostingResponse response = careerService.getJobById(1L, 2L);

            assertThat(response).isNotNull();
            assertThat(response.getJobId()).isEqualTo(1L);
            assertThat(response.getTitle()).isEqualTo("Software Engineer");
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when job not found")
        void shouldThrowExceptionWhenJobNotFound() {
            when(jobPostingRepository.findById(99L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.getJobById(99L, 2L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Job not found");
        }

        @Test
        @DisplayName("Should mark job as saved when user has saved it")
        void shouldMarkJobAsSavedForUser() {
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.of(jobPosting));
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(true);

            JobPostingResponse response = careerService.getJobById(1L, 2L);

            assertThat(response.isSaved()).isTrue();
        }
    }

    // =====================================================
    // SAVE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("saveJob()")
    class SaveJobTests {

        @Test
        @DisplayName("Should save job successfully when not already saved")
        void shouldSaveJobSuccessfully() {
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(false);
            when(userRepository.findById(2L)).thenReturn(Optional.of(studentUser));
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.of(jobPosting));
            when(savedJobRepository.save(any(SavedJob.class))).thenReturn(new SavedJob());

            careerService.saveJob(1L, 2L);

            verify(savedJobRepository, times(1)).save(any(SavedJob.class));
        }

        @Test
        @DisplayName("Should throw BadRequestException when job already saved")
        void shouldThrowExceptionWhenAlreadySaved() {
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(true);

            assertThatThrownBy(() -> careerService.saveJob(1L, 2L))
                    .isInstanceOf(BadRequestException.class)
                    .hasMessageContaining("Job already saved");

            verify(savedJobRepository, never()).save(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when user not found")
        void shouldThrowExceptionWhenUserNotFound() {
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(false);
            when(userRepository.findById(2L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.saveJob(1L, 2L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("User not found");
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when job not found")
        void shouldThrowExceptionWhenJobNotFound() {
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(false);
            when(userRepository.findById(2L)).thenReturn(Optional.of(studentUser));
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.saveJob(1L, 2L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Job not found");
        }
    }

    // =====================================================
    // UNSAVE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("unsaveJob()")
    class UnsaveJobTests {

        @Test
        @DisplayName("Should unsave job successfully when job is saved")
        void shouldUnsaveJobSuccessfully() {
            SavedJob savedJob = SavedJob.builder()
                    .savedJobId(1L)
                    .user(studentUser)
                    .jobPosting(jobPosting)
                    .build();

            when(savedJobRepository.findByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(Optional.of(savedJob));

            careerService.unsaveJob(1L, 2L);

            verify(savedJobRepository, times(1)).delete(savedJob);
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when saved job not found")
        void shouldThrowExceptionWhenSavedJobNotFound() {
            when(savedJobRepository.findByUser_UserIdAndJobPosting_JobId(2L, 1L))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.unsaveJob(1L, 2L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Saved job not found");
        }
    }

    // =====================================================
    // DELETE JOB TESTS
    // =====================================================
    @Nested
    @DisplayName("deleteJobPosting()")
    class DeleteJobPostingTests {

        @Test
        @DisplayName("Should delete job successfully when owner deletes it")
        void shouldDeleteJobSuccessfully() {
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.of(jobPosting));

            careerService.deleteJobPosting(1L, 1L);

            verify(jobPostingRepository, times(1)).delete(jobPosting);
        }

        @Test
        @DisplayName("Should throw ForbiddenException when non-owner tries to delete")
        void shouldThrowExceptionWhenNotOwner() {
            when(jobPostingRepository.findById(1L)).thenReturn(Optional.of(jobPosting));

            assertThatThrownBy(() -> careerService.deleteJobPosting(1L, 2L))
                    .isInstanceOf(ForbiddenException.class)
                    .hasMessageContaining("You can only delete your own job postings");

            verify(jobPostingRepository, never()).delete(any());
        }

        @Test
        @DisplayName("Should throw ResourceNotFoundException when job not found")
        void shouldThrowExceptionWhenJobNotFound() {
            when(jobPostingRepository.findById(99L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> careerService.deleteJobPosting(99L, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Job not found");
        }
    }

    // =====================================================
    // GET ALL COMPANIES & LOCATIONS TESTS
    // =====================================================
    @Nested
    @DisplayName("getAllCompanies() and getAllLocations()")
    class FilterOptionsTests {

        @Test
        @DisplayName("Should return list of all company names")
        void shouldReturnAllCompanies() {
            when(jobPostingRepository.findAllCompanyNames())
                    .thenReturn(List.of("Google", "Amazon", "Meta"));

            List<String> companies = careerService.getAllCompanies();

            assertThat(companies).hasSize(3);
            assertThat(companies).contains("Google", "Amazon", "Meta");
        }

        @Test
        @DisplayName("Should return list of all locations")
        void shouldReturnAllLocations() {
            when(jobPostingRepository.findAllLocations())
                    .thenReturn(List.of("Remote", "New York", "London"));

            List<String> locations = careerService.getAllLocations();

            assertThat(locations).hasSize(3);
            assertThat(locations).contains("Remote", "New York", "London");
        }

        @Test
        @DisplayName("Should return empty list when no companies exist")
        void shouldReturnEmptyListWhenNoCompanies() {
            when(jobPostingRepository.findAllCompanyNames()).thenReturn(List.of());

            List<String> companies = careerService.getAllCompanies();

            assertThat(companies).isEmpty();
        }
    }

    // =====================================================
    // GET JOBS BY TYPE TESTS
    // =====================================================
    @Nested
    @DisplayName("getJobsByType()")
    class GetJobsByTypeTests {

        @Test
        @DisplayName("Should return only full time jobs when filtered by FULL_TIME")
        void shouldReturnJobsByType() {
            Pageable pageable = PageRequest.of(0, 10);
            Page<JobPosting> jobPage = new PageImpl<>(List.of(jobPosting));

            when(jobPostingRepository.findByJobTypeOrderByCreatedAtDesc(JobType.FULL_TIME, pageable))
                    .thenReturn(jobPage);
            when(savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(anyLong(), anyLong()))
                    .thenReturn(false);

            Page<JobPostingResponse> result = careerService.getJobsByType(
                    JobType.FULL_TIME, pageable, 2L);

            assertThat(result.getContent()).hasSize(1);
            assertThat(result.getContent().get(0).getJobType()).isEqualTo(JobType.FULL_TIME);
        }

        @Test
        @DisplayName("Should return empty page when no jobs of given type exist")
        void shouldReturnEmptyPageWhenNoJobsOfType() {
            Pageable pageable = PageRequest.of(0, 10);
            when(jobPostingRepository.findByJobTypeOrderByCreatedAtDesc(JobType.INTERNSHIP, pageable))
                    .thenReturn(new PageImpl<>(List.of()));

            Page<JobPostingResponse> result = careerService.getJobsByType(
                    JobType.INTERNSHIP, pageable, 2L);

            assertThat(result.getContent()).isEmpty();
        }
    }
}