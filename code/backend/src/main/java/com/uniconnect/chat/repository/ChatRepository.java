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
    public List<MessageParticipantState> states(Collection<Long> messages) {
        if(messages.isEmpty()) return List.of();
        return em.createQuery("select s from MessageParticipantState s where s.messageId in :messages",MessageParticipantState.class)
                .setParameter("messages",messages).getResultList();
    }
    public <T> T insertAndFlush(T entity) { em.persist(entity); em.flush(); return entity; }
    public void insertParticipants(long conversation,long low,long high,java.time.LocalDateTime joinedAt) {
        em.createNativeQuery("insert into chat_participants(conversation_id,user_id,slot,joined_at) " +
                        "values (:conversation,:low,1,:joined),(:conversation,:high,2,:joined)")
                .setParameter("conversation",conversation).setParameter("low",low).setParameter("high",high)
                .setParameter("joined",joinedAt).executeUpdate();
    }
    public void insertMessageStates(long message,long conversation,long low,long high) {
        em.createNativeQuery("insert into chat_message_states(message_id,conversation_id,user_id) " +
                        "values (:message,:conversation,:low),(:message,:conversation,:high)")
                .setParameter("message",message).setParameter("conversation",conversation)
                .setParameter("low",low).setParameter("high",high).executeUpdate();
    }
    public void hideConversation(long conversation, long user, java.time.LocalDateTime now) {
        em.createQuery("update MessageParticipantState s set s.deletedForSelfAt=:now where s.conversationId=:conversation and s.userId=:user and s.deletedForSelfAt is null")
                .setParameter("now",now).setParameter("conversation",conversation).setParameter("user",user).executeUpdate();
        em.createQuery("update ConversationParticipant p set p.hidden=true where p.conversationId=:conversation and p.userId=:user")
                .setParameter("conversation",conversation).setParameter("user",user).executeUpdate();
    }
    public void showConversation(long conversation) {
        em.createQuery("update ConversationParticipant p set p.hidden=false where p.conversationId=:conversation")
                .setParameter("conversation",conversation).executeUpdate();
    }
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
    public List<ChatMessage> latestVisible(Collection<Long> conversations,long user) {
        if(conversations.isEmpty()) return List.of();
        return em.createQuery("select m from ChatMessage m, MessageParticipantState s " +
                        "where m.conversationId in :conversations and s.messageId=m.messageId and s.userId=:user " +
                        "and s.deletedForSelfAt is null and not exists (select newer.messageId from ChatMessage newer, " +
                        "MessageParticipantState newerState where newer.conversationId=m.conversationId " +
                        "and newer.messageId>m.messageId and newerState.messageId=newer.messageId " +
                        "and newerState.userId=:user and newerState.deletedForSelfAt is null)",ChatMessage.class)
                .setParameter("conversations",conversations).setParameter("user",user).getResultList();
    }
    public Map<Long,Long> unreadCounts(Collection<Long> conversations,long user) {
        if(conversations.isEmpty()) return Map.of();
        var rows=em.createQuery("select m.conversationId,count(m) from ChatMessage m, MessageParticipantState s " +
                        "where m.conversationId in :conversations and s.messageId=m.messageId and s.userId=:user " +
                        "and m.senderId<>:user and s.readAt is null and s.deletedForSelfAt is null " +
                        "and m.deletedForEveryoneAt is null group by m.conversationId",Object[].class)
                .setParameter("conversations",conversations).setParameter("user",user).getResultList();
        Map<Long,Long> result=new HashMap<>();
        for(var row:rows) result.put((Long)row[0],(Long)row[1]);
        return result;
    }
    public List<Conversation> conversations(long user,int page,int size) {
        return em.createQuery("select c from Conversation c, ConversationParticipant p where p.conversationId=c.conversationId and p.userId=:user and p.hidden=false order by c.lastMessageAt desc,c.conversationId desc",Conversation.class)
                .setParameter("user",user).setFirstResult(page*size).setMaxResults(size).getResultList();
    }
    public long conversationCount(long user) {
        return em.createQuery("select count(p) from ConversationParticipant p where p.userId=:user and p.hidden=false",Long.class).setParameter("user",user).getSingleResult();
    }
}
