package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorExpertise;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MentorExpertiseRepository extends JpaRepository<MentorExpertise, Long> {
    List<MentorExpertise> findByMentorProfileMentorProfileId(Long mentorProfileId);
}
