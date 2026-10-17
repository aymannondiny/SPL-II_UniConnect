package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.ApplicationException;
import org.springframework.http.HttpStatus;

public class InvalidSessionException extends ApplicationException {
    public InvalidSessionException() {
        super(HttpStatus.UNAUTHORIZED, "INVALID_SESSION", "The session is invalid or expired.");
    }
}
