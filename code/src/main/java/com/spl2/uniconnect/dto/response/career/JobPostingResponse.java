package com.spl2.uniconnect.dto.response.career;

import com.spl2.uniconnect.domain.career.JobType;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class JobPostingResponse {

    private Long jobId;
    private String title;
    private String companyName;
    private JobType jobType;
    private String location;
    private String description;
    private String requirements;
    private String applicationLink;
    private String applicationEmail;
    private LocalDate applicationDeadline;
    private String salaryRange;
    private Long postedByUserId;
    private String postedByName;
    private LocalDateTime createdAt;
    private boolean isSaved;
    private boolean isActive;
}