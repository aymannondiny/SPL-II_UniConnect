package com.spl2.uniconnect.dto.response.common;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {

    private boolean success;

    private String message;

    private T data;

    private String error;  // ✅ ADD THIS for error messages

    private Integer status;  // ✅ ADD THIS for HTTP status codes

    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();

    // =====================================================
    // SUCCESS RESPONSES
    // =====================================================

    /**
     * Success response with data
     */
    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(LocalDateTime.now())
                .build();
    }

    /**
     * Success response without data
     */
    public static <T> ApiResponse<T> success(String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
    }

    // =====================================================
    // ERROR RESPONSES
    // =====================================================

    /**
     * Error response with message only
     */
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .error(message)
                .timestamp(LocalDateTime.now())
                .build();
    }

    /**
     * Error response with message and HTTP status
     */
    public static <T> ApiResponse<T> error(String message, Integer status) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .error(message)
                .status(status)
                .timestamp(LocalDateTime.now())
                .build();
    }
}

// =====================================================
// DOCUMENTATION
// =====================================================
//
// ApiResponse<T>
// │
// ├── Fields
// │   ├── success    → Did the request succeed? (true/false)
// │   ├── message    → Human-readable message (what happened?)
// │   ├── data       → The actual response data (nullable, only on success)
// │   ├── error      → ✅ NEW: Error message (only on failure)
// │   ├── status     → ✅ NEW: HTTP status code (only on error)
// │   └── timestamp  → When the response was generated
// │
// ├── Annotations
// │   ├── @JsonInclude → Hide null fields in JSON output
// │   ├── @Builder      → Enable builder pattern for object creation
// │   ├── @Data         → Generate getters/setters
// │   ├── @NoArgsConstructor → Generate no-arg constructor
// │   └── @AllArgsConstructor → Generate all-args constructor
// │
// └── Factory Methods
//     ├── success(msg, data) → ✅ Request succeeded with data
//     ├── success(msg)       → ✅ Request succeeded, no data
//     ├── error(msg)         → ✅ NEW: Request failed with message only
//     └── error(msg, status) → ✅ NEW: Request failed with message and status
//
// =====================================================
// USAGE EXAMPLES
// =====================================================
//
// SUCCESS RESPONSES:
// ─────────────────
// ApiResponse.success("Project created", projectData)
// → { "success": true, "message": "Project created", "data": {...}, "timestamp": "..." }
//
// ApiResponse.success("Connection removed")
// → { "success": true, "message": "Connection removed", "timestamp": "..." }
//
// ERROR RESPONSES:
// ───────────────
// ApiResponse.error("Project not found")
// → { "success": false, "message": "Project not found", "error": "Project not found", "timestamp": "..." }
//
// ApiResponse.error("Invalid request", 400)
// → { "success": false, "message": "Invalid request", "error": "Invalid request", "status": 400, "timestamp": "..." }
//
// =====================================================