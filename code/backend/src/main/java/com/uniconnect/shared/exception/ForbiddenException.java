package com.uniconnect.shared.exception;

import org.springframework.http.HttpStatus;

public final class ForbiddenException extends ApplicationException {
    public ForbiddenException(String message) { super(HttpStatus.FORBIDDEN, "ACCESS_DENIED", message); }
}
