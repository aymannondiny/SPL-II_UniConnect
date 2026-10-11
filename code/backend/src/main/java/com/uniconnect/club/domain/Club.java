package com.uniconnect.club.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.Locale;

@Entity
@Table(name = "clubs")
public class Club {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long clubId;
    @Column(nullable = false, length = 150) private String clubName;
    @Column(nullable = false, unique = true, length = 150) private String nameKey;
    @Column(nullable = false, length = 100) private String category;
    @Column(nullable = false, length = 5000) private String description;
    @Column(length = 2048) private String logoUrl;
    @Column(length = 320) private String contactEmail;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 30) private ClubStatus status;
    @Column(nullable = false) private LocalDateTime createdAt;
    @Column(nullable = false) private LocalDateTime updatedAt;
    protected Club() {}
    public Club(String name, String category, String description, String logo, String email, LocalDateTime now) {
        clubName = name; nameKey = key(name); this.category = category; this.description = description;
        logoUrl = logo; contactEmail = email; status = ClubStatus.ACTIVE; createdAt = now; updatedAt = now;
    }
    public static String key(String name) { return name.strip().toLowerCase(Locale.ROOT); }
    public Long getId() { return clubId; }
    public String getClubName() { return clubName; }
    public String getCategory() { return category; }
    public String getDescription() { return description; }
    public String getLogoUrl() { return logoUrl; }
    public String getContactEmail() { return contactEmail; }
    public ClubStatus getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
