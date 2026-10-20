package com.uniconnect.mentorship.dto;

public record MentorSearchCriteria(
        String topic,
        Long departmentId,
        Integer yearOfStudy,
        int page,
        int size
) {
    public MentorSearchCriteria {
        topic = (topic != null && !topic.isBlank()) ? topic.strip() : null;
        if (page < 0) page = 0;
        if (size <= 0) size = 20;
        if (size > 100) size = 100;
    }

    public static MentorSearchCriteria of(String topic, Long departmentId, Integer yearOfStudy, int page, int size) {
        return new MentorSearchCriteria(topic, departmentId, yearOfStudy, page, size);
    }
}
