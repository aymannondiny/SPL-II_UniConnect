package com.spl2.uniconnect.domain.user;

import com.spl2.uniconnect.domain.academic.Department;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "club_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClubProfile {

    @Id
    @Column(name = "club_id")
    private Long clubId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "club_id", nullable = false, updatable = false)
    @MapsId
    private User user;

    @NotBlank(message = "Club name is required")
    @Size(min = 3, max = 255, message = "Club name must be between 3 and 255 characters")
    @Column(name = "club_name", unique = true, nullable = false, length = 255)
    private String clubName;

    @NotBlank(message = "Club description is required")
    @Size(min = 10, max = 5000, message = "Description must be between 10 and 5000 characters")
    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    private String description;

    @NotBlank(message = "Club category is required")
    @Pattern(regexp = "^(Academic|Sports|Cultural|Tech|Arts|Service|Other)$",
            message = "Category must be one of: Academic, Sports, Cultural, Tech, Arts, Service, Other")
    @Column(name = "category", nullable = false, length = 50)
    private String category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department; // Optional: for department-specific clubs

    @Min(value = 1900, message = "Founded year must be valid")
    @Max(value = 2024, message = "Founded year cannot be in the future")
    @Column(name = "founded_year")
    private Integer foundedYear;

    @Size(max = 255, message = "Meeting schedule cannot exceed 255 characters")
    @Column(name = "meeting_schedule", length = 255)
    private String meetingSchedule;

    @Size(max = 255, message = "Contact email cannot exceed 255 characters")
    @Email(message = "Contact email must be valid")
    @Column(name = "contact_email", length = 255)
    private String contactEmail;

    @Size(max = 500, message = "Website URL cannot exceed 500 characters")
    @Column(name = "website_url", length = 500)
    @Pattern(regexp = "^(https?://)?([\\da-z.-]+)\\.([a-z.]{2,6})?(/[/\\w .-]*)?/?$|^$",
            message = "Invalid URL format")
    private String websiteUrl;

    @Size(max = 500, message = "Club logo cannot exceed 500 characters")
    @Column(name = "club_logo", length = 500)
    private String clubLogo;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}