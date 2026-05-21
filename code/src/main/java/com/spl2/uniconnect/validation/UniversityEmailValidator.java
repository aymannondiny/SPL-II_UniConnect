package com.spl2.uniconnect.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

public class UniversityEmailValidator implements ConstraintValidator<ValidUniversityEmail, String> {

//    private static final String ALLOWED_DOMAIN = "@iut-dhaka.edu";

    @Override
    public void initialize(ValidUniversityEmail constraintAnnotation) {
        // No initialization needed
    }

    @Override
    public boolean isValid(String email, ConstraintValidatorContext context) {
        if (email == null || email.isBlank()) {
            return false; // @NotBlank handles this
        }

//        return email.toLowerCase().endsWith(ALLOWED_DOMAIN);

        return email.toLowerCase().matches("^[a-zA-Z0-9._%+-]+@iut-dhaka\\.edu$");
    }
}