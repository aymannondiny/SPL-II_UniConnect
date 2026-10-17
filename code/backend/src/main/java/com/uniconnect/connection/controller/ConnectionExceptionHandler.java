package com.uniconnect.connection.controller;

import com.uniconnect.shared.exception.ApiError;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.List;
import org.springframework.core.annotation.Order;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice(basePackageClasses = ConnectionController.class)
@Order(0)
public class ConnectionExceptionHandler {
    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<ApiError> conflict(HttpServletRequest request) {
        return ResponseEntity.status(409).body(new ApiError(Instant.now(), 409, "Conflict", "CONNECTION_DATA_CONFLICT",
                "Connection data changed or an open connection already exists. Reload before retrying.",
                request.getRequestURI(), List.of()));
    }
}
