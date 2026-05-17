package com.spl2.uniconnect.domain.user;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "admin_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminProfile {

    @Id
    @Column(name = "admin_id")
    private Long adminId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_id", nullable = false, updatable = false)
    @MapsId
    private User user;

    @NotBlank(message = "Admin role is required")
    @Size(min = 3, max = 100, message = "Admin role must be between 3 and 100 characters")
    @Column(name = "admin_role", nullable = false, length = 100)
    private String adminRole; // e.g., "Super Admin", "Content Moderator", "User Manager"
}