package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.ApplicationException;
import org.springframework.http.HttpStatus;

public final class PasswordResetDeliveryException extends ApplicationException {
    public PasswordResetDeliveryException() {
        super(HttpStatus.SERVICE_UNAVAILABLE, "PASSWORD_RESET_EMAIL_UNAVAILABLE",
                "Password reset email could not be sent. Please try again later.");
    }
}
