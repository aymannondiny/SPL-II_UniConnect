package com.uniconnect.shared.exception;

import org.springframework.http.HttpStatus;

public final class ResourceNotFoundException extends ApplicationException {

    public ResourceNotFoundException(
            String resourceName,
            Object identifier
    ) {
        super(
                HttpStatus.NOT_FOUND,
                "RESOURCE_NOT_FOUND",
                "%s with identifier '%s' was not found."
                        .formatted(resourceName, identifier)
        );
    }
}
