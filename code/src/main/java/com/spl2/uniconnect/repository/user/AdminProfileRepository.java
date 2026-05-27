package com.spl2.uniconnect.repository.user;

import com.spl2.uniconnect.domain.user.AdminProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AdminProfileRepository extends JpaRepository<AdminProfile, Long> {

    // =====================================================
    // BASIC LOOKUPS
    // =====================================================

    // ✅ Find admin profile by user ID
    Optional<AdminProfile> findByUserUserId(Long userId);

    // Find admin profile with user details (avoid N+1)
    @Query("SELECT ap FROM AdminProfile ap " +
            "JOIN FETCH ap.user " +
            "WHERE ap.user.userId = :userId")
    Optional<AdminProfile> findByIdWithUser(@Param("userId") Long userId);

    // Find admins by role
    List<AdminProfile> findByAdminRole(String adminRole);

    // Check if admin role exists
    boolean existsByAdminRole(String adminRole);

    // =====================================================
    // ANALYTICS
    // =====================================================

    // Find all distinct admin roles
    @Query("SELECT DISTINCT ap.adminRole FROM AdminProfile ap " +
            "WHERE ap.adminRole IS NOT NULL")
    List<String> findAllDistinctRoles();

    // Count admins by role
    @Query("SELECT ap.adminRole, COUNT(ap) FROM AdminProfile ap " +
            "GROUP BY ap.adminRole")
    List<Object[]> countByAdminRole();
}