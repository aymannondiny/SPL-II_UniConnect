package com.spl2.uniconnect.controller.notification;

import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.spl2.uniconnect.dto.response.common.ApiResponse;
import com.spl2.uniconnect.dto.response.notification.NotificationResponse;
import com.spl2.uniconnect.mapper.NotificationMapper;
import com.spl2.uniconnect.security.SecurityUtils;
import com.spl2.uniconnect.service.notification.NotificationService;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
public class NotificationController {

    private final NotificationService notificationService;
    private final NotificationMapper notificationMapper;

    @GetMapping
    public ApiResponse<?> getAll(Pageable pageable) {
        Long userId = SecurityUtils.getCurrentUserId();
        Page<NotificationResponse> page = notificationService
                .getMyNotifications(userId, pageable)
                .map(notificationMapper::toResponse);

        return ApiResponse.success("Notifications retrieved", page);
    }

    @GetMapping("/{id}")
    public ApiResponse<?> getById(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        NotificationResponse response =
                notificationMapper.toResponse(notificationService.getById(id, userId));

        return ApiResponse.success("Notification retrieved", response);
    }

    @GetMapping("/unread")
    public ApiResponse<?> getUnread(Pageable pageable) {
        Long userId = SecurityUtils.getCurrentUserId();
        Page<NotificationResponse> page = notificationService
                .getMyNotifications(userId, pageable)
                .map(notificationMapper::toResponse);

        return ApiResponse.success("Unread notifications retrieved", page);
    }

    @GetMapping("/unread-count")
    public ApiResponse<?> unreadCount() {
        Long userId = SecurityUtils.getCurrentUserId();
        return ApiResponse.success("Unread count",
                notificationService.getUnreadCount(userId));
    }

    @PutMapping("/{id}/read")
    public ApiResponse<?> markAsRead(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.markAsRead(id, userId);
        return ApiResponse.success("Notification marked as read");
    }

    @PutMapping("/read-all")
    public ApiResponse<?> markAll() {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.markAllAsRead(userId);
        return ApiResponse.success("All notifications marked as read");
    }

    @DeleteMapping("/{id}")
    public ApiResponse<?> delete(@PathVariable Long id) {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.deleteNotification(id, userId);
        return ApiResponse.success("Notification deleted");
    }

    @DeleteMapping
    public ApiResponse<?> deleteAll() {
        Long userId = SecurityUtils.getCurrentUserId();
        notificationService.deleteAllForUser(userId);
        return ApiResponse.success("All notifications deleted");
    }
}