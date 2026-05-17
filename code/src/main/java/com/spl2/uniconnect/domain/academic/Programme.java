package com.spl2.uniconnect.domain.academic;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "programmes",
uniqueConstraints = @UniqueConstraint(columnNames = {"department_id", "programme_code"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Programme {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "programme_id")
    private Long programmeId;

    @NotNull(message = "Department is required")
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @NotBlank(message = "Programme name is required")
    @Size(min = 3, max = 255, message = "Programme name must be between 3 and 255 characters")
    @Column(name = "programme_name", nullable = false, length = 255)
    private String programmeName;

    @NotBlank(message = "Programme code is required")
    @Pattern(regexp = "^[A-Z]{2,10}$", message = "Programme code must be 2-10 uppercase letters")
    @Column(name = "programme_code", nullable = false, length = 20)
    private String programmeCode;

    @Size(max = 5000, message = "Description cannot exceed 5000 characters")
    @Column(columnDefinition = "TEXT")
    private String description;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
