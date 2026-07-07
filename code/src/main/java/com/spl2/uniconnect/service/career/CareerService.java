package com.spl2.uniconnect.service.career;

import com.spl2.uniconnect.domain.career.JobPosting;
import com.spl2.uniconnect.domain.career.JobType;
import com.spl2.uniconnect.domain.career.SavedJob;
import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.dto.request.career.CreateJobRequest;
import com.spl2.uniconnect.dto.response.career.JobPostingResponse;
import com.spl2.uniconnect.exception.BadRequestException;
import com.spl2.uniconnect.exception.ForbiddenException;
import com.spl2.uniconnect.exception.ResourceNotFoundException;
import com.spl2.uniconnect.repository.career.JobPostingRepository;
import com.spl2.uniconnect.repository.career.SavedJobRepository;
import com.spl2.uniconnect.repository.user.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class CareerService {

    private final JobPostingRepository jobPostingRepository;
    private final SavedJobRepository savedJobRepository;
    private final UserRepository userRepository;

    @Transactional
    public JobPostingResponse createJobPosting(CreateJobRequest request, Long currentUserId) {
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        JobPosting job = JobPosting.builder()
                .postedBy(user)
                .title(request.getTitle())
                .companyName(request.getCompanyName())
                .jobType(request.getJobType())
                .location(request.getLocation())
                .description(request.getDescription())
                .requirements(request.getRequirements())
                .applicationLink(request.getApplicationLink())
                .applicationEmail(request.getApplicationEmail())
                .applicationDeadline(request.getApplicationDeadline())
                .salaryRange(request.getSalaryRange())
                .build();

        JobPosting saved = jobPostingRepository.save(job);
        log.info("Job created: {} by user: {}", saved.getJobId(), currentUserId);
        return mapToResponse(saved, currentUserId);
    }

    @Transactional(readOnly = true)
    public Page<JobPostingResponse> getAllJobs(Pageable pageable, Long currentUserId) {
        return jobPostingRepository.findAllByOrderByCreatedAtDesc(pageable)
                .map(job -> mapToResponse(job, currentUserId));
    }

    @Transactional(readOnly = true)
    public Page<JobPostingResponse> searchJobs(String query, Pageable pageable, Long currentUserId) {
        return jobPostingRepository.searchJobs(query, pageable)
                .map(job -> mapToResponse(job, currentUserId));
    }

    @Transactional(readOnly = true)
    public Page<JobPostingResponse> getJobsByType(JobType jobType, Pageable pageable, Long currentUserId) {
        return jobPostingRepository.findByJobTypeOrderByCreatedAtDesc(jobType, pageable)
                .map(job -> mapToResponse(job, currentUserId));
    }

    @Transactional(readOnly = true)
    public JobPostingResponse getJobById(Long jobId, Long currentUserId) {
        JobPosting job = jobPostingRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Job not found: " + jobId));
        return mapToResponse(job, currentUserId);
    }

    @Transactional
    public void saveJob(Long jobId, Long currentUserId) {
        if (savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(currentUserId, jobId)) {
            throw new BadRequestException("Job already saved");
        }
        User user = userRepository.findById(currentUserId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        JobPosting job = jobPostingRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Job not found"));

        savedJobRepository.save(SavedJob.builder()
                .user(user)
                .jobPosting(job)
                .build());
        log.info("Job {} saved by user {}", jobId, currentUserId);
    }

    @Transactional
    public void unsaveJob(Long jobId, Long currentUserId) {
        SavedJob savedJob = savedJobRepository
                .findByUser_UserIdAndJobPosting_JobId(currentUserId, jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Saved job not found"));
        savedJobRepository.delete(savedJob);
        log.info("Job {} unsaved by user {}", jobId, currentUserId);
    }

    @Transactional(readOnly = true)
    public Page<JobPostingResponse> getMySavedJobs(Pageable pageable, Long currentUserId) {
        return savedJobRepository.findByUser_UserIdOrderBySavedAtDesc(currentUserId, pageable)
                .map(savedJob -> mapToResponse(savedJob.getJobPosting(), currentUserId));
    }

    @Transactional
    public void deleteJobPosting(Long jobId, Long currentUserId) {
        JobPosting job = jobPostingRepository.findById(jobId)
                .orElseThrow(() -> new ResourceNotFoundException("Job not found"));
        if (!job.getPostedBy().getUserId().equals(currentUserId)) {
            throw new ForbiddenException("You can only delete your own job postings");
        }
        jobPostingRepository.delete(job);
        log.info("Job {} deleted by user {}", jobId, currentUserId);
    }

    @Transactional(readOnly = true)
    public List<String> getAllCompanies() {
        return jobPostingRepository.findAllCompanyNames();
    }

    @Transactional(readOnly = true)
    public List<String> getAllLocations() {
        return jobPostingRepository.findAllLocations();
    }

    private JobPostingResponse mapToResponse(JobPosting job, Long currentUserId) {
        boolean isSaved = currentUserId != null &&
                savedJobRepository.existsByUser_UserIdAndJobPosting_JobId(
                        currentUserId, job.getJobId());

        return JobPostingResponse.builder()
                .jobId(job.getJobId())
                .title(job.getTitle())
                .companyName(job.getCompanyName())
                .jobType(job.getJobType())
                .location(job.getLocation())
                .description(job.getDescription())
                .requirements(job.getRequirements())
                .applicationLink(job.getApplicationLink())
                .applicationEmail(job.getApplicationEmail())
                .applicationDeadline(job.getApplicationDeadline())
                .salaryRange(job.getSalaryRange())
                .postedByUserId(job.getPostedBy().getUserId())
                .postedByName(job.getPostedBy().getFullName())
                .createdAt(job.getCreatedAt())
                .isSaved(isSaved)
                .isActive(job.isActive())
                .build();
    }
}