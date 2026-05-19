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

    @Builder.Default
    private LocalDateTime timestamp = LocalDateTime.now();

    // Success response with data
    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .data(data)
                .timestamp(LocalDateTime.now())
                .build();
    }

    // Success response without data
    public static <T> ApiResponse<T> success(String message) {
        return ApiResponse.<T>builder()
                .success(true)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
    }

    // Error response
    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
                .success(false)
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
    }
}

//ApiResponse<T>
//│
//        ├── Fields
//│   ├── success    → did it work?
//        │   ├── message    → what happened?
//        │   ├── data       → the result (nullable)
//│   └── timestamp  → when?
//        │
//        ├── Annotations
//│   ├── @JsonInclude  → hide null fields in JSON
//│   ├── @Builder      → build objects piece by piece
//│   └── @Builder.Default → keep timestamp default in builder
//│
//        └── Factory Methods
//    ├── success(msg, data) → worked, here's data
//        ├── success(msg)       → worked, no data
//    └── error(msg)         → something went wrong