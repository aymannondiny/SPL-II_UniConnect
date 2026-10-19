package com.uniconnect.career.repository;

import com.uniconnect.career.domain.SavedJob;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.Collection;
import java.util.Set;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SavedJobRepository extends JpaRepository<SavedJob, Long> {
    boolean existsByStudentUserIdAndJobPostJobPostId(long studentUserId, long jobPostId);
    Optional<SavedJob> findByStudentUserIdAndJobPostJobPostId(long studentUserId, long jobPostId);
    Page<SavedJob> findByStudentUserId(long studentUserId, Pageable pageable);

    @Query("select s.jobPost.jobPostId from SavedJob s where s.studentUserId=:student and s.jobPost.jobPostId in :posts")
    Set<Long> findSavedPostIds(@Param("student") long studentUserId, @Param("posts") Collection<Long> postIds);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from SavedJob s where s.savedJobId=:id")
    Optional<SavedJob> lockById(@Param("id") long id);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from SavedJob s where s.studentUserId=:student and s.jobPost.jobPostId=:post")
    Optional<SavedJob> lockByStudentAndPost(@Param("student") long studentUserId, @Param("post") long jobPostId);
}
