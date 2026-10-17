package com.uniconnect.shared.exception;

import org.springframework.http.HttpStatus;

public final class BadRequestException extends ApplicationException {

    public BadRequestException(String code, String message) {
        super(
                HttpStatus.BAD_REQUEST,
                code,
                message
        );
    }
}
