package com.uniconnect.profile.controller;

import com.uniconnect.shared.exception.ApiError;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.List;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/** Convert database conflicts after the service transaction has rolled back, without leaking submitted data. */
@RestControllerAdvice(basePackageClasses = PersonalProfileController.class)
@Order(0)
public class ProfileExceptionHandler {
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<ApiError> invalidIdentifier(HttpServletRequest request) {
        return ResponseEntity.badRequest().body(new ApiError(Instant.now(), 400, "Bad Request", "VALIDATION_FAILED",
                "The requested identifier is invalid.", request.getRequestURI(), List.of()));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<ApiError> conflict(HttpServletRequest request) {
        return ResponseEntity.status(409).body(new ApiError(Instant.now(), 409, "Conflict", "PROFILE_DATA_CONFLICT",
                "A unique value is already in use or related data changed. Reload and check your values before retrying.",
                request.getRequestURI(), List.of()));
    }
}
