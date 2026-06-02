package com.spl2.uniconnect.repository.notification;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.spl2.uniconnect.domain.notification.Notification;
import com.spl2.uniconnect.domain.notification.NotificationType;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // Get all notifications for a user
    Page<Notification> findByUserUserId(Long userId, Pageable pageable);

    // Get unread notifications for a user
    @Query("SELECT n FROM Notification n WHERE n.user.userId = :userId AND n.isRead = false")
    List<Notification> findUnreadByUserId(@Param("userId") Long userId);

    // Count unread notifications
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.user.userId = :userId AND n.isRead = false")
    long countUnreadByUserId(@Param("userId") Long userId);

    // Get notifications by type
    Page<Notification> findByUserUserIdAndType(Long userId, NotificationType type, Pageable pageable);

    // Delete all notifications for a user
    void deleteByUserUserId(Long userId);
}