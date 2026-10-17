package com.uniconnect.shared.exception;

import org.springframework.http.HttpStatus;

public final class ConflictException extends ApplicationException {

    public ConflictException(String code, String message) {
        super(
                HttpStatus.CONFLICT,
                code,
                message
        );
    }
}
