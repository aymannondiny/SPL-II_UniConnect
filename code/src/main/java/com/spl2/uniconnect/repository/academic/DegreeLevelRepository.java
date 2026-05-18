package com.spl2.uniconnect.repository.academic;

import com.spl2.uniconnect.domain.academic.DegreeLevel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DegreeLevelRepository extends JpaRepository<DegreeLevel, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    Optional<DegreeLevel> findByDegreeName(String degreeName);

    boolean existsByDegreeName(String degreeName);

    List<DegreeLevel> findAllByOrderByMinYearsAsc();


     // Find degree levels within a duration range\
    List<DegreeLevel> findByMinYearsLessThanEqualAndMaxYearsGreaterThanEqual(
            int maxYears,
            int minYears
    );
}