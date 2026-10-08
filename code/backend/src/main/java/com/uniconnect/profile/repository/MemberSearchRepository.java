package com.uniconnect.profile.repository;

import com.uniconnect.profile.domain.PersonalProfile;
import com.uniconnect.profile.dto.MemberSearch;
import com.uniconnect.shared.dto.PageResponse;
import jakarta.persistence.EntityManager;
import java.util.*;
import org.springframework.stereotype.Repository;

/** Applies field visibility in SQL before filtering, counting, sorting, or pagination. */
@Repository
public class MemberSearchRepository {
    private final EntityManager em;
    public MemberSearchRepository(EntityManager em) { this.em = em; }
    public PageResponse<PersonalProfile> search(long viewer, Collection<Long> accepted, MemberSearch search) {
        Map<String, Object> parameters = new LinkedHashMap<>();
        StringBuilder where = new StringBuilder(" from PersonalProfile p join p.user u where u.accountStatus = com.uniconnect.shared.security.AccountStatus.ACTIVE and u.anonymizedAt is null and u.platformRole in (com.uniconnect.shared.security.PlatformRole.STUDENT, com.uniconnect.shared.security.PlatformRole.ALUMNI) and u.userId <> :viewer");
        parameters.put("viewer", viewer);
        if (search.name() != null) add(where, parameters, "locate(:name, lower(u.fullName)) > 0", "name", search.name());
        if (search.role() != null) add(where, parameters, "u.platformRole = :role", "role", search.role());
        if (search.departmentId() != null) add(where, parameters, "p.programmeDegree.programme.department.departmentId = :department", "department", search.departmentId());
        if (search.programmeId() != null) add(where, parameters, "p.programmeDegree.programme.programmeId = :programme", "programme", search.programmeId());
        boolean detailsFilter = !search.skills().isEmpty() || search.yearOfStudy() != null || search.projectAvailable() != null
                || search.mentorshipAvailable() != null || search.company() != null || search.industry() != null || search.graduationYear() != null;
        if (detailsFilter) {
            where.append(" and (p.detailsVisibility = com.uniconnect.profile.domain.ProfileVisibility.ALL_MEMBERS");
            if (!accepted.isEmpty()) { where.append(" or u.userId in :accepted"); parameters.put("accepted", accepted); }
            where.append(")");
        }
        for (int i = 0; i < search.skills().size(); i++) {
            String key = "skill" + i;
            add(where, parameters, "exists (select s.skillId from PersonalProfile sp join sp.skills s where sp.profileId = p.profileId and s.name = :" + key + ")", key, search.skills().get(i));
        }
        if (search.yearOfStudy() != null) add(where, parameters, "treat(p as StudentProfile).yearOfStudy = :year", "year", search.yearOfStudy());
        if (search.projectAvailable() != null) add(where, parameters, "treat(p as StudentProfile).projectAvailability = :project", "project", search.projectAvailable());
        if (search.mentorshipAvailable() != null) add(where, parameters, "treat(p as StudentProfile).mentorshipAvailability = :mentorship", "mentorship", search.mentorshipAvailable());
        if (search.company() != null) add(where, parameters, "locate(:company, lower(treat(p as AlumniProfile).currentCompany)) > 0", "company", search.company());
        if (search.industry() != null) add(where, parameters, "locate(:industry, lower(treat(p as AlumniProfile).industry)) > 0", "industry", search.industry());
        if (search.graduationYear() != null) add(where, parameters, "treat(p as AlumniProfile).graduationYear = :graduation", "graduation", search.graduationYear());
        String order = search.sort().equals("NAME_DESC") ? " order by lower(u.fullName) desc, u.userId" : " order by lower(u.fullName), u.userId";
        var query = em.createQuery("select p" + where + order, PersonalProfile.class);
        var count = em.createQuery("select count(p)" + where, Long.class);
        parameters.forEach((key, value) -> { query.setParameter(key, value); count.setParameter(key, value); });
        return new PageResponse<>(query.setFirstResult(search.page() * search.size()).setMaxResults(search.size()).getResultList(),
                search.page(), search.size(), count.getSingleResult());
    }
    private void add(StringBuilder where, Map<String, Object> parameters, String predicate, String key, Object value) {
        where.append(" and ").append(predicate);
        parameters.put(key, value);
    }
}
