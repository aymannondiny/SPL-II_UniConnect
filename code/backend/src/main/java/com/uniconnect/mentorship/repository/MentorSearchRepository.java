package com.uniconnect.mentorship.repository;

import com.uniconnect.mentorship.domain.MentorProfile;
import com.uniconnect.mentorship.domain.MentorStatus;
import com.uniconnect.mentorship.dto.MentorSearchCriteria;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.AccountStatus;
import jakarta.persistence.EntityManager;
import org.springframework.stereotype.Repository;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Repository
public class MentorSearchRepository {

    private final EntityManager em;

    public MentorSearchRepository(EntityManager em) {
        this.em = em;
    }

    public PageResponse<MentorProfile> search(MentorSearchCriteria criteria) {
        Map<String, Object> parameters = new LinkedHashMap<>();
        StringBuilder where = new StringBuilder(" FROM MentorProfile m WHERE m.status = :status AND m.user.accountStatus = :accountStatus AND m.user.anonymizedAt IS NULL");
        parameters.put("status", MentorStatus.AVAILABLE);
        parameters.put("accountStatus", AccountStatus.ACTIVE);

        if (criteria.topic() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM MentorExpertise e JOIN e.skill s WHERE e.mentorProfile = m AND LOWER(s.name) LIKE LOWER(CONCAT('%', :topic, '%')))");
            parameters.put("topic", criteria.topic());
        }

        if (criteria.departmentId() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM PersonalProfile p WHERE p.user = m.user AND p.programmeDegree.programme.department.departmentId = :departmentId)");
            parameters.put("departmentId", criteria.departmentId());
        }

        if (criteria.yearOfStudy() != null) {
            where.append(" AND EXISTS (SELECT 1 FROM PersonalProfile p WHERE p.user = m.user AND treat(p as StudentProfile).yearOfStudy = :yearOfStudy)");
            parameters.put("yearOfStudy", criteria.yearOfStudy());
        }

        String order = " ORDER BY m.registeredAt DESC, m.mentorProfileId DESC";

        var query = em.createQuery("SELECT DISTINCT m" + where + order, MentorProfile.class);
        var count = em.createQuery("SELECT count(DISTINCT m)" + where, Long.class);

        parameters.forEach((key, value) -> {
            query.setParameter(key, value);
            count.setParameter(key, value);
        });

        int firstResult = criteria.page() * criteria.size();
        query.setFirstResult(firstResult).setMaxResults(criteria.size());

        List<MentorProfile> results = query.getResultList();
        long total = count.getSingleResult();

        return new PageResponse<>(results, criteria.page(), criteria.size(), total);
    }
}
