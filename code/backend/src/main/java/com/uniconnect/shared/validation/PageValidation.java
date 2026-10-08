package com.uniconnect.shared.validation;
import com.uniconnect.shared.exception.BadRequestException;
public final class PageValidation {
    private PageValidation() {}
    public static void check(int page, int size) {
        if (page < 0 || page > 100000 || size < 1 || size > 50)
            throw new BadRequestException("INVALID_PAGE", "Page must be 0–100000 and size 1–50.");
    }
}
