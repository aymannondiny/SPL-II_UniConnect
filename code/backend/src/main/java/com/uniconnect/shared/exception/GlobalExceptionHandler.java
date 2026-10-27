package com.uniconnect.shared.exception;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

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

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<ApiError> handleMalformedRequest(
            HttpMessageNotReadableException exception,
            HttpServletRequest request
    ) {
        ApiError error = createError(
                HttpStatus.BAD_REQUEST,
                "MALFORMED_REQUEST",
                "Request body is malformed or unreadable.",
                request.getRequestURI(),
                List.of()
        );

        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(error);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    ResponseEntity<ApiError> handleNoResourceFound(
            NoResourceFoundException exception,
            HttpServletRequest request
    ) {
        ApiError error = createError(
                HttpStatus.NOT_FOUND,
                "RESOURCE_NOT_FOUND",
                "The requested resource was not found.",
                request.getRequestURI(),
                List.of()
        );

        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .body(error);
    }

    @ExceptionHandler(org.springframework.web.method.annotation.MethodArgumentTypeMismatchException.class)
    ResponseEntity<ApiError> handleInvalidParameter(
            org.springframework.web.method.annotation.MethodArgumentTypeMismatchException exception,
            HttpServletRequest request) {
        return ResponseEntity.badRequest().body(createError(HttpStatus.BAD_REQUEST,
                "INVALID_PARAMETER", "A request parameter has an invalid value.", request.getRequestURI(), List.of()));
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> handleUnexpectedException(
            Exception exception,
            HttpServletRequest request
    ) {
        // A broken database connection may be wrapped by a failed transaction rollback.
        // Preserve a useful retryable response without exposing connection details.
        Throwable cause = exception;
        for (int depth = 0; cause != null && depth < 20; depth++, cause = cause.getCause()) {
            if (cause instanceof org.springframework.dao.DataAccessResourceFailureException
                    || cause instanceof org.springframework.dao.QueryTimeoutException
                    || cause instanceof org.springframework.dao.CannotAcquireLockException
                    || cause instanceof java.sql.SQLException sql
                        && sql.getSQLState() != null && sql.getSQLState().startsWith("08")) {
                LOGGER.warn("Database unavailable while processing {}", request.getRequestURI(), exception);
                return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(createError(
                        HttpStatus.SERVICE_UNAVAILABLE, "DATABASE_UNAVAILABLE",
                        "UniConnect is temporarily unavailable. Please try again shortly.",
                        request.getRequestURI(), List.of()));
            }
        }
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
