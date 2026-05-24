package com.spl2.uniconnect.dto.request.user;

import jakarta.validation.constraints.*;
import lombok.Data;

@Data
public class UpdateClubProfileRequest {

    // Required fields
    @NotBlank(message = "Club name is required")
    @Size(min = 3, max = 255, message = "Club name must be between 3 and 255 characters")
    private String clubName;

    @NotBlank(message = "Description is required")
    @Size(min = 10, max = 5000, message = "Description must be between 10 and 5000 characters")
    private String description;

    @NotBlank(message = "Category is required")
    @Pattern(regexp = "^(Academic|Sports|Cultural|Tech|Arts|Service|Other)$",
            message = "Category must be one of: Academic, Sports, Cultural, Tech, Arts, Service, Other")
    private String category;

    // Optional fields
    @Min(value = 1900, message = "Founded year must be valid")
    @Max(value = 2100, message = "Founded year must be valid")
    private Integer foundedYear;

    @Size(max = 255, message = "Meeting schedule cannot exceed 255 characters")
    private String meetingSchedule;

    @Email(message = "Contact email must be valid")
    @Size(max = 255, message = "Contact email cannot exceed 255 characters")
    private String contactEmail;

    @Pattern(regexp = "^(https?://)?([\\da-z.-]+)\\.([a-z.]{2,6})?(/[/\\w .-]*)?/?$|^$",
            message = "Invalid URL format")
    @Size(max = 500, message = "Website URL cannot exceed 500 characters")
    private String websiteUrl;

    @Size(max = 500, message = "Club logo URL cannot exceed 500 characters")
    private String clubLogo;

    // Optional: link to department
    private Long departmentId;
}