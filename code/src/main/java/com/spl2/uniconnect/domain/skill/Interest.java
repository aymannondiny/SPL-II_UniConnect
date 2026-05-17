package com.spl2.uniconnect.domain.skill;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.*;

@Entity
@Table(name = "interests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Interest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "interest_id")
    private Long interestId;

    @NotBlank(message = "Interest name is required")
    @Size(min = 2, max = 100, message = "Interest name must be between 2 and 100 characters")
    @Column(name = "interest_name", unique = true, nullable = false, length = 100)
    private String interestName;
}
