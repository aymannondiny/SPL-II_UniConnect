package com.uniconnect.career.service;

import com.uniconnect.career.repository.JobPostRepository;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Career-owned privacy hook for a future account-anonymization transaction. */
@Service
public class CareerAuthorPrivacyService {
    private final JobPostRepository posts;
    private final Clock clock;

    public CareerAuthorPrivacyService(JobPostRepository posts, Clock clock) {
        this.posts = posts;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void redactAuthor(long authorUserId) {
        LocalDateTime now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        posts.lockAllByAuthor(authorUserId).forEach(post -> post.redactAuthor(now));
        posts.flush();
    }
}
