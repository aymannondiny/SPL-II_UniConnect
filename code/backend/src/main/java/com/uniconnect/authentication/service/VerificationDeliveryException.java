package com.uniconnect.authentication.service;

import com.uniconnect.shared.exception.ApplicationException;
import org.springframework.http.HttpStatus;

public final class VerificationDeliveryException extends ApplicationException {
    public VerificationDeliveryException() {
        super(HttpStatus.SERVICE_UNAVAILABLE, "VERIFICATION_EMAIL_UNAVAILABLE",
                "Verification email could not be sent. Please try again later.");
    }
}
