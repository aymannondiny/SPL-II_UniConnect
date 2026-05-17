package com.spl2.uniconnect.domain.academic;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "departments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Department {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "department_id")
    private Long departmentId;

    @NotBlank(message = "Department name is required")
    @Size(min = 3, max = 255, message = "Department name mudt be between 3 and 255 characters")
    @Column(name = "department_name", unique = true, nullable = false, length = 255)
    private String departmentName;

    @NotBlank(message = "Department code is required")
    @Pattern(regexp = "^[A-Z]{2,10}$", message = "Department code must be 2 - 10 uppercase letters")
    @Column(name = "department_code", unique = true, nullable = false, length = 20)
    private String departmentCode;

    @Size(max = 5000, message = "Description cannot exceed 5000 characters")
    @Column(columnDefinition = "TEXT")
    private String description;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

}
