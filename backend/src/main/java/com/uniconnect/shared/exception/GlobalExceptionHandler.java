package com.uniconnect.shared.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.Instant;
import java.util.List;

@RestControllerAdvice
public final class GlobalExceptionHandler {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApplicationException.class)
    ResponseEntity<ApiError> handleApplicationException(
            ApplicationException exception,
            HttpServletRequest request
    ) {
        ApiError error = createError(
                exception.status(),
                exception.code(),
                exception.getMessage(),
                request.getRequestURI(),
                List.of()
        );

        return ResponseEntity
                .status(exception.status())
                .body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiError> handleValidationException(
            MethodArgumentNotValidException exception,
            HttpServletRequest request
    ) {
        List<ApiError.FieldViolation> fieldErrors =
                exception.getBindingResult()
                        .getFieldErrors()
                        .stream()
                        .map(fieldError -> new ApiError.FieldViolation(
                                fieldError.getField(),
                                fieldError.getDefaultMessage() == null
                                        ? "Invalid value."
                                        : fieldError.getDefaultMessage()
                        ))
                        .toList();

        ApiError error = createError(
                HttpStatus.BAD_REQUEST,
                "VALIDATION_FAILED",
                "Request validation failed.",
                request.getRequestURI(),
                fieldErrors
        );

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(error);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> handleUnexpectedException(
            Exception exception,
            HttpServletRequest request
    ) {
        LOGGER.error(
                "Unhandled exception while processing request path {}",
                request.getRequestURI(),
                exception
        );

        ApiError error = createError(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "An unexpected server error occurred.",
                request.getRequestURI(),
                List.of()
        );

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(error);
    }

    private ApiError createError(
            HttpStatus status,
            String code,
            String message,
            String path,
            List<ApiError.FieldViolation> fieldErrors
    ) {
        return new ApiError(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                code,
                message,
                path,
                fieldErrors
        );
    }
}
