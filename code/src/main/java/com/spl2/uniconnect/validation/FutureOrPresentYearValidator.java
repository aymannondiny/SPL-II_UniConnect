package com.spl2.uniconnect.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.time.Year;

public class FutureOrPresentYearValidator
        implements ConstraintValidator<FutureOrPresentYear, Integer> {

    private int maxYearsAhead;

    @Override
    public void initialize(FutureOrPresentYear annotation) {
        this.maxYearsAhead = annotation.maxYearsAhead();
    }

    @Override
    public boolean isValid(Integer year, ConstraintValidatorContext context) {
        // Null is handled by @NotNull if needed
        if (year == null) return true;

        int currentYear = Year.now().getValue();
        int maxAllowedYear = currentYear + maxYearsAhead;

        boolean isValid = year >= currentYear && year <= maxAllowedYear;

        if (!isValid) {
            // Custom error message with dynamic years
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(
                    "Graduation year must be between " + currentYear +
                            " and " + maxAllowedYear
            ).addConstraintViolation();
        }

        return isValid;
    }
}