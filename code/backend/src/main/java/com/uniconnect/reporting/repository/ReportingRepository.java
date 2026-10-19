package com.uniconnect.reporting.repository;

import com.uniconnect.reporting.domain.*;
import jakarta.persistence.*;
import java.util.*;
import org.springframework.stereotype.Repository;

@Repository
public class ReportingRepository {
    private final EntityManager em;
    public ReportingRepository(EntityManager em){this.em=em;}
    public <T>T insert(T value){em.persist(value);em.flush();return value;}
    public void flush(){em.flush();}
    public ContentReport lock(long id){return em.find(ContentReport.class,id,LockModeType.PESSIMISTIC_WRITE);}
    public ContentReport find(long id){return em.find(ContentReport.class,id);}
    public List<ContentReport> reporter(long reporter,int page,int size){return em.createQuery(
            "select r from ContentReport r where r.reporterId=:reporter order by r.reportId desc",ContentReport.class)
            .setParameter("reporter",reporter).setFirstResult(page*size).setMaxResults(size).getResultList();}
    public long reporterCount(long reporter){return em.createQuery("select count(r) from ContentReport r where r.reporterId=:reporter",Long.class)
            .setParameter("reporter",reporter).getSingleResult();}
    public List<ContentReport> queue(ReportStatus status,ReportTargetType type,int page,int size){
        String where=(status==null?"":" and r.status=:status")+(type==null?"":" and r.targetType=:type");
        var q=em.createQuery("select r from ContentReport r where 1=1"+where+" order by r.reportId desc",ContentReport.class);
        if(status!=null)q.setParameter("status",status);if(type!=null)q.setParameter("type",type);
        return q.setFirstResult(page*size).setMaxResults(size).getResultList();}
    public long queueCount(ReportStatus status,ReportTargetType type){
        String where=(status==null?"":" and r.status=:status")+(type==null?"":" and r.targetType=:type");
        var q=em.createQuery("select count(r) from ContentReport r where 1=1"+where,Long.class);
        if(status!=null)q.setParameter("status",status);if(type!=null)q.setParameter("type",type);return q.getSingleResult();}
    public List<ReportAuditLog> history(long report){return em.createQuery(
            "select a from ReportAuditLog a where a.reportId=:report order by a.auditId",ReportAuditLog.class)
            .setParameter("report",report).getResultList();}
    public ReportActionLink action(long report){return em.createQuery("select a from ReportActionLink a where a.reportId=:report",ReportActionLink.class)
            .setParameter("report",report).getResultStream().findFirst().orElse(null);}
}
