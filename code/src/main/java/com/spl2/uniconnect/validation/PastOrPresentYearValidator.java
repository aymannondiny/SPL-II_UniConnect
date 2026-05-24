package com.spl2.uniconnect.validation;

import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;

import java.time.Year;

public class PastOrPresentYearValidator
        implements ConstraintValidator<PastOrPresentYear, Integer> {

    private int minYearsBack;

    @Override
    public void initialize(PastOrPresentYear annotation) {
        this.minYearsBack = annotation.minYearsBack();
    }

    @Override
    public boolean isValid(Integer year, ConstraintValidatorContext context) {
        // Null is handled by @NotNull if needed
        if (year == null) return true;

        int currentYear = Year.now().getValue();
        int minAllowedYear = currentYear - minYearsBack;

        boolean isValid = year >= minAllowedYear && year <= currentYear;

        if (!isValid) {
            // Custom error message with dynamic years
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(
                    "Founded year must be between " + minAllowedYear +
                            " and " + currentYear
            ).addConstraintViolation();
        }

        return isValid;
    }
}