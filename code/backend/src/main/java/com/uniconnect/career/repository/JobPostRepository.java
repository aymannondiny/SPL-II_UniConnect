package com.uniconnect.career.repository;

import com.uniconnect.career.domain.JobPost;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface JobPostRepository extends JpaRepository<JobPost, Long>, JpaSpecificationExecutor<JobPost> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from JobPost p where p.jobPostId=:id")
    Optional<JobPost> lockById(@Param("id") long id);

    Page<JobPost> findByAuthorUserId(long authorUserId, Pageable pageable);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from JobPost p where p.authorUserId=:author order by p.jobPostId")
    List<JobPost> lockAllByAuthor(@Param("author") long authorUserId);
}
