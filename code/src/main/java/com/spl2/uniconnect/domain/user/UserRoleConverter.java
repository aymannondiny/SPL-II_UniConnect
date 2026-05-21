package com.spl2.uniconnect.domain.user;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class UserRoleConverter implements AttributeConverter<UserRole, String> {

    @Override
    public String convertToDatabaseColumn(UserRole role) {
        if (role == null) return null;
        return role.getDbValue(); // Saves "Student" to DB
    }

    @Override
    public UserRole convertToEntityAttribute(String dbValue) {
        if (dbValue == null) return null;
        for (UserRole role : UserRole.values()) {
            if (role.getDbValue().equals(dbValue)) {
                return role; // Reads "Student" from DB → STUDENT enum
            }
        }
        throw new IllegalArgumentException("Unknown role in database: " + dbValue);
    }
}