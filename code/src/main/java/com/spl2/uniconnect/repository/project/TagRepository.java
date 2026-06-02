package com.spl2.uniconnect.repository.project;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.project.Tag;

import java.util.Optional;

@Repository
public interface TagRepository extends JpaRepository<Tag, Long> {

    // =====================================================
    // BASIC QUERIES
    // =====================================================

    /**
     * Find tag by name
     */
    Optional<Tag> findByTagName(String tagName);

    /**
     * Check if tag exists
     */
    @Query("SELECT CASE WHEN COUNT(t) > 0 THEN true ELSE false END FROM Tag t WHERE LOWER(t.tagName) = LOWER(:tagName)")
    boolean existsByTagNameIgnoreCase(@Param("tagName") String tagName);

    /**
     * Find or create tag (case-insensitive)
     */
    @Query("SELECT t FROM Tag t WHERE LOWER(t.tagName) = LOWER(:tagName)")
    Optional<Tag> findByTagNameIgnoreCase(@Param("tagName") String tagName);
}