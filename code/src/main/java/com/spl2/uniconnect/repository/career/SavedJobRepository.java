package com.spl2.uniconnect.repository.career;

import com.spl2.uniconnect.domain.career.SavedJob;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SavedJobRepository extends JpaRepository<SavedJob, Long> {

    Page<SavedJob> findByUser_UserIdOrderBySavedAtDesc(Long userId, Pageable pageable);

    boolean existsByUser_UserIdAndJobPosting_JobId(Long userId, Long jobId);

    Optional<SavedJob> findByUser_UserIdAndJobPosting_JobId(Long userId, Long jobId);

    long countByJobPosting_JobId(Long jobId);
}