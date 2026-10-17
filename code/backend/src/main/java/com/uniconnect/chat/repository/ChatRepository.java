package com.uniconnect.chat.repository;
import com.uniconnect.chat.domain.*;
import jakarta.persistence.EntityManager;
import java.util.*;
import org.springframework.stereotype.Repository;
@Repository
public class ChatRepository {
    private final EntityManager em;
    public ChatRepository(EntityManager em) { this.em=em; }
    public record Pair(long low, long high) { public boolean includes(long id) { return low==id || high==id; } public long other(long id) { return low==id ? high : low; } }
    public Optional<Pair> pair(long conversation) {
        return em.createQuery("select c.userLow,c.userHigh from Conversation c where c.conversationId=:id", Object[].class)
                .setParameter("id",conversation).getResultStream().findFirst().map(r -> new Pair((Long)r[0],(Long)r[1]));
    }
    public Optional<Long> messageConversation(long message) {
        return em.createQuery("select m.conversationId from ChatMessage m where m.messageId=:id",Long.class)
                .setParameter("id",message).getResultStream().findFirst();
    }
    public Optional<Conversation> findPair(long low,long high) {
        return em.createQuery("select c from Conversation c where c.userLow=:low and c.userHigh=:high",Conversation.class)
                .setParameter("low",low).setParameter("high",high).getResultStream().findFirst();
    }
    public Conversation conversation(long id) { return em.find(Conversation.class,id); }
    public ChatMessage message(long id) { return em.find(ChatMessage.class,id); }
    public Optional<ChatMessage> clientMessage(long sender,UUID clientId) {
        return em.createQuery("select m from ChatMessage m where m.senderId=:sender and m.clientMessageId=:client",ChatMessage.class)
                .setParameter("sender",sender).setParameter("client",clientId).getResultStream().findFirst();
    }
    public MessageParticipantState state(long message,long user) {
        return em.createQuery("select s from MessageParticipantState s where s.messageId=:message and s.userId=:user",MessageParticipantState.class)
                .setParameter("message",message).setParameter("user",user).getSingleResult();
    }
    public <T> T insert(T entity) { em.persist(entity); em.flush(); return entity; }
    public List<ChatMessage> visible(long conversation,long user,Long before,int size) {
        String filter=before==null ? "" : " and m.messageId < :before";
        var query=em.createQuery("select m from ChatMessage m, MessageParticipantState s where m.conversationId=:conversation and s.messageId=m.messageId and s.userId=:user and s.deletedForSelfAt is null"+filter+" order by m.messageId desc",ChatMessage.class)
                .setParameter("conversation",conversation).setParameter("user",user);
        if(before!=null) query.setParameter("before",before);
        return query.setMaxResults(size).getResultList();
    }
    public long unread(long conversation,long user) {
        return em.createQuery("select count(m) from ChatMessage m, MessageParticipantState s where m.conversationId=:conversation and s.messageId=m.messageId and s.userId=:user and m.senderId<>:user and s.readAt is null and s.deletedForSelfAt is null and m.deletedForEveryoneAt is null",Long.class)
                .setParameter("conversation",conversation).setParameter("user",user).getSingleResult();
    }
    public List<Conversation> conversations(long user,int page,int size) {
        return em.createQuery("select c from Conversation c where c.userLow=:user or c.userHigh=:user order by c.lastMessageAt desc,c.conversationId desc",Conversation.class)
                .setParameter("user",user).setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public long conversationCount(long user) {
        return em.createQuery("select count(c) from Conversation c where c.userLow=:user or c.userHigh=:user",Long.class).setParameter("user",user).getSingleResult();
    }
}
