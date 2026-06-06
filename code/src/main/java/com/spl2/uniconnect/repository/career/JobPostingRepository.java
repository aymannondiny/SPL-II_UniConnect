package com.spl2.uniconnect.repository.career;

import com.spl2.uniconnect.domain.career.JobPosting;
import com.spl2.uniconnect.domain.career.JobType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface JobPostingRepository extends JpaRepository<JobPosting, Long> {

    Page<JobPosting> findByPostedBy_UserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    Page<JobPosting> findByJobTypeOrderByCreatedAtDesc(JobType jobType, Pageable pageable);

    Page<JobPosting> findByLocationContainingIgnoreCaseOrderByCreatedAtDesc(
            String location, Pageable pageable);

    @Query("SELECT j FROM JobPosting j WHERE " +
            "LOWER(j.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(j.companyName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(j.description) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<JobPosting> searchJobs(@Param("query") String query, Pageable pageable);

    Page<JobPosting> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @Query("SELECT DISTINCT j.companyName FROM JobPosting j ORDER BY j.companyName")
    List<String> findAllCompanyNames();

    @Query("SELECT DISTINCT j.location FROM JobPosting j ORDER BY j.location")
    List<String> findAllLocations();
}