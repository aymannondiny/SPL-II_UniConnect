package com.uniconnect.career.mapper;

import com.uniconnect.career.domain.ApplicationChannel;
import com.uniconnect.career.domain.CareerPostAvailability;
import com.uniconnect.career.domain.JobPost;
import com.uniconnect.career.domain.SavedJob;
import com.uniconnect.career.dto.CareerPostResponse;
import com.uniconnect.career.dto.CareerSkillResponse;
import com.uniconnect.career.dto.SavedJobResponse;
import java.time.LocalDate;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
public class CareerMapper {
    public CareerPostResponse post(JobPost post, String authorName, Map<Long, String> skillNames,
            LocalDate today, boolean saved, boolean studentViewer) {
        CareerPostAvailability availability = post.availability(today);
        boolean removed = availability == CareerPostAvailability.REMOVED;
        boolean redacted = availability == CareerPostAvailability.UNAVAILABLE;
        boolean canApply = studentViewer && post.isActive(today);
        var channels = new LinkedHashSet<ApplicationChannel>();
        if (!removed && !redacted) {
            if (post.getApplicationUrl() != null) channels.add(ApplicationChannel.URL);
            if (post.getApplicationEmail() != null) channels.add(ApplicationChannel.EMAIL);
        }
        var skills = removed ? java.util.List.<CareerSkillResponse>of() : post.getSkills().stream()
                .map(skill -> new CareerSkillResponse(skill.getSkillId(),
                        skillNames.getOrDefault(skill.getSkillId(), "Unavailable skill"), skill.isRequired()))
                .sorted(java.util.Comparator.comparing(CareerSkillResponse::name))
                .toList();
        return new CareerPostResponse(post.getJobPostId(), removed || redacted ? null : post.getAuthorUserId(),
                removed ? null : redacted ? "Former User" : authorName,
                removed ? null : post.getTitle(), removed ? null : post.getCompanyName(),
                removed ? null : post.getDescription(), removed ? null : post.getQualifications(),
                removed ? null : post.getLocation(), removed ? null : post.getEmploymentType(),
                removed ? null : post.getWorkMode(), removed ? null : post.getSalaryRange(),
                removed || redacted ? null : post.getApplicationUrl(),
                removed || redacted ? null : post.getApplicationEmail(), removed ? null : post.getApplicationDeadline(),
                availability, saved, canApply, Set.copyOf(channels), skills, removed ? null : post.getPostedAt(),
                removed ? null : post.getUpdatedAt(), removed ? null : post.getClosedAt());
    }

    public SavedJobResponse saved(SavedJob saved, CareerPostResponse post) {
        return new SavedJobResponse(saved.getSavedJobId(), saved.getNote(), saved.getSavedAt(),
                saved.getUpdatedAt(), post);
    }
}
