package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.User;
import com.spl2.uniconnect.domain.user.UserRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    Page<User> findByRole(UserRole role, Pageable pageable);
    Optional<User> findByEmailAndEmailVerified(String email, boolean emailVerified);

    // =====================================================
    // SEARCH (PostgreSQL Full-Text Search)
    // =====================================================

    @Query("SELECT u FROM User u WHERE LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<User> searchByFullName(@Param("query") String query, Pageable pageable);

    @Query("SELECT u FROM User u WHERE " +
            "LOWER(u.fullName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<User> searchByNameOrEmail(@Param("query") String query, Pageable pageable);

    @Query(value = "SELECT * FROM users WHERE " +
            "to_tsvector('english', full_name || ' ' || email) @@ " +
            "plainto_tsquery('english', :query)",
            nativeQuery = true)
    List<User> fullTextSearch(@Param("query") String query);

    // =====================================================
    // ROLE-BASED QUERIES
    // =====================================================

    long countByRole(UserRole role);

    Page<User> findByRoleAndEmailVerified(UserRole role, boolean emailVerified, Pageable pageable);

    @Query("SELECT u FROM User u WHERE u.emailVerified = false")
    List<User> findAllUnverifiedUsers();
}