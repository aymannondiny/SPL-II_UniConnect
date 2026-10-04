package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.ApplicationException;
import org.springframework.http.HttpStatus;

public class InvalidCredentialsException extends ApplicationException {
    public InvalidCredentialsException() {
        super(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS", "Unable to sign in with these credentials.");
    }
}
