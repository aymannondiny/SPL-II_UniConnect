package com.uniconnect.chat.service;
import com.uniconnect.authentication.service.*;
import com.uniconnect.chat.domain.*;
import com.uniconnect.chat.dto.*;
import com.uniconnect.chat.mapper.ChatMapper;
import com.uniconnect.chat.repository.ChatRepository;
import com.uniconnect.connection.service.ConnectionQueryService;
import com.uniconnect.notification.service.ChatNotificationService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.SessionPrincipal;
import com.uniconnect.shared.validation.PageValidation;
import jakarta.validation.Validator;
import java.time.*;
import java.util.*;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ChatService {
    public record ReportableMessage(long messageId,long conversationId,long senderId,String content,
            LocalDateTime sentAt,LocalDateTime deletedForEveryoneAt) {}
    private final ChatRepository chats;
    private final MemberAccountService pairs;
    private final ProfileAccountService accounts;
    private final ChatAccountService accountDetails;
    private final ConnectionQueryService connections;
    private final ChatNotificationService notifications;
    private final ChatMapper mapper;
    private final Validator validator;
    private final Clock clock;
    private final ApplicationEventPublisher events;
    private final ChatPerformanceDiagnostics performance;
    public ChatService(ChatRepository chats,MemberAccountService pairs,ProfileAccountService accounts,
            ChatAccountService accountDetails,ConnectionQueryService connections,ChatMapper mapper,
            ChatNotificationService notifications,Validator validator,Clock clock,ApplicationEventPublisher events,
            ChatPerformanceDiagnostics performance) {
        this.chats=chats; this.pairs=pairs; this.accounts=accounts; this.accountDetails=accountDetails;
        this.connections=connections; this.mapper=mapper; this.notifications=notifications;
        this.validator=validator; this.clock=clock; this.events=events;
        this.performance=performance;
    }
    public MessageResponse send(SessionPrincipal actor,SendMessageRequest request) {
        var timing=performance.start(request==null?null:request.clientMessageId());
        if(request==null || !validator.validate(request).isEmpty()) throw new BadRequestException("INVALID_MESSAGE","Message requires a receiver, client UUID, and 1–5000 nonblank characters.");
        var sender=pairs.lockPair(actor,request.receiverId(),true);
        if(!connections.areAccepted(actor.userId(),request.receiverId())) throw new ForbiddenException("An accepted connection is required to send messages.");
        timing.mark("authorization");
        var existing=chats.clientMessage(actor.userId(),request.clientMessageId());
        if(existing.isPresent()) {
            var m=existing.get(); var c=chats.conversation(m.getConversationId());
            if(c.other(actor.userId())!=request.receiverId() || !m.getContent().equals(request.content()))
                throw new ConflictException("MESSAGE_RETRY_CONFLICT","This clientMessageId was used for a different message.");
            requireVisible(m,actor.userId());
            timing.finishAfterCommit("idempotent-retry");
            return response(m,c);
        }
        var now=now();
        var conversation=chats.findPair(Math.min(actor.userId(),request.receiverId()),Math.max(actor.userId(),request.receiverId())).orElse(null);
        if(conversation==null) {
            conversation=chats.insertAndFlush(new Conversation(actor.userId(),request.receiverId(),now));
            chats.insertParticipants(conversation.getId(),conversation.getUserLow(),conversation.getUserHigh(),now);
        }
        timing.mark("conversation");
        var message=chats.insertAndFlush(new ChatMessage(conversation.getId(),actor.userId(),request.clientMessageId(),request.content(),now));
        chats.insertMessageStates(message.getId(),conversation.getId(),conversation.getUserLow(),conversation.getUserHigh());
        timing.mark("message-persistence");
        notifications.messageReceived(request.receiverId(), conversation.getId(), message.getId(),
                sender.isAnonymized()?"Former User":sender.getFullName(), now);
        timing.mark("notification");
        conversation.messageSent(now);
        changed(conversation);
        timing.finishAfterCommit("complete");
        return mapper.sent(message);
    }
    public PageResponse<ConversationResponse> list(SessionPrincipal actor,int page,int size) {
        accounts.activeAccount(actor);
        PageValidation.check(page,size);
        var conversations=chats.conversations(actor.userId(),page,size);
        var conversationIds=conversations.stream().map(Conversation::getId).toList();
        var otherIds=conversations.stream().map(c->c.other(actor.userId())).toList();
        var details=accountDetails.summaries(otherIds);
        var accepted=connections.acceptedAmong(actor.userId(),otherIds);
        var latestByConversation=new HashMap<Long,ChatMessage>();
        for(var message:chats.latestVisible(conversationIds,actor.userId())) latestByConversation.put(message.getConversationId(),message);
        var unread=chats.unreadCounts(conversationIds,actor.userId());
        var statesByMessage=new HashMap<Long,Map<Long,MessageParticipantState>>();
        for(var state:chats.states(latestByConversation.values().stream().map(ChatMessage::getId).toList()))
            statesByMessage.computeIfAbsent(state.getMessageId(),ignored->new HashMap<>()).put(state.getUserId(),state);
        var items=conversations.stream().map(c -> {
            long otherId=c.other(actor.userId());
            var other=details.get(otherId);
            var latest=latestByConversation.get(c.getId());
            MessageResponse latestResponse=null;
            if(latest!=null) {
                long recipient=latest.getSenderId().equals(actor.userId())?otherId:actor.userId();
                latestResponse=mapper.message(latest,statesByMessage.get(latest.getId()).get(recipient));
            }
            return new ConversationResponse(c.getId(),otherId,other.name(),other.active() && accepted.contains(otherId),
                    c.getCreatedAt(),c.getLastMessageAt(),latestResponse,unread.getOrDefault(c.getId(),0L));
        }).toList();
        return new PageResponse<>(items,page,size,chats.conversationCount(actor.userId()));
    }
    /** Opening a page marks only the visible incoming messages actually returned as read. */
    public HistoryResponse history(SessionPrincipal actor,long conversationId,Long before,int size) {
        PageValidation.check(0,size);
        if(before!=null && before<=0) throw new BadRequestException("INVALID_CURSOR","Message cursor must be positive.");
        var c=lockedConversation(actor,conversationId);
        var messages=new ArrayList<>(chats.visible(conversationId,actor.userId(),before,size+1));
        boolean more=messages.size()>size;
        if(more) messages.removeLast();
        Long next=more?messages.getLast().getId():null;
        var statesByMessage=new HashMap<Long,Map<Long,MessageParticipantState>>();
        for(var state:chats.states(messages.stream().map(ChatMessage::getId).toList()))
            statesByMessage.computeIfAbsent(state.getMessageId(),ignored->new HashMap<>())
                    .put(state.getUserId(),state);
        boolean updated=false;
        for(var m:messages) if(!m.getSenderId().equals(actor.userId()) && m.getDeletedForEveryoneAt()==null)
            updated=statesByMessage.get(m.getId()).get(actor.userId()).read(now()) || updated;
        if(updated) changed(c);
        Collections.reverse(messages);
        boolean canSend=accountDetails.summary(c.other(actor.userId())).active() && connections.areAccepted(actor.userId(),c.other(actor.userId()));
        var responses=messages.stream().map(m -> {
            long recipient=m.getSenderId().equals(actor.userId())?c.other(actor.userId()):actor.userId();
            return mapper.message(m,statesByMessage.get(m.getId()).get(recipient));
        }).toList();
        return new HistoryResponse(c.getId(),canSend,responses,more,next);
    }
    public MessageResponse delivered(SessionPrincipal actor,long messageId) { return receipt(actor,messageId,false); }
    public MessageResponse read(SessionPrincipal actor,long messageId) { return receipt(actor,messageId,true); }
    private MessageResponse receipt(SessionPrincipal actor,long messageId,boolean read) {
        var c=lockedMessage(actor,messageId); var m=chats.message(messageId);
        requireVisible(m,actor.userId());
        if(m.getSenderId().equals(actor.userId())) throw new ForbiddenException("Only the recipient may acknowledge delivery or reading.");
        if(m.getDeletedForEveryoneAt()!=null) throw new ConflictException("MESSAGE_DELETED","Deleted messages cannot be acknowledged.");
        var state=chats.state(messageId,actor.userId());
        boolean updated=read?state.read(now()):state.delivered(now());
        if(updated) changed(c);
        return response(m,c);
    }
    public void deleteForSelf(SessionPrincipal actor,long messageId) {
        lockedMessage(actor,messageId);
        if(chats.state(messageId,actor.userId()).deleteForSelf(now())) events.publishEvent(new ChatChanged(Set.of(actor.userId())));
    }
    public void deleteForEveryone(SessionPrincipal actor,long messageId) {
        var c=lockedMessage(actor,messageId); var m=chats.message(messageId);
        if(!m.getSenderId().equals(actor.userId())) throw new ForbiddenException("Only the sender may delete for everyone.");
        if(m.deleteForEveryone(now())) changed(c);
    }
    public ReportableMessage reportableMessage(SessionPrincipal actor,long messageId){
        lockedMessage(actor,messageId);var message=chats.message(messageId);requireVisible(message,actor.userId());
        return new ReportableMessage(message.getId(),message.getConversationId(),message.getSenderId(),message.getContent(),
                message.getSentAt(),message.getDeletedForEveryoneAt());
    }
    private Conversation lockedMessage(SessionPrincipal actor,long messageId) {
        return lockedConversation(actor,chats.messageConversation(messageId).orElseThrow(() -> missing("Message",messageId)),"Message",messageId);
    }
    private Conversation lockedConversation(SessionPrincipal actor,long id) {
        return lockedConversation(actor,id,"Conversation",id);
    }
    private Conversation lockedConversation(SessionPrincipal actor,long id,String resource,long publicId) {
        if(actor==null) throw new InvalidSessionException();
        var pair=chats.pair(id).orElseThrow(() -> missing(resource,publicId));
        if(!pair.includes(actor.userId())) throw missing(resource,publicId);
        // Same lock order as connection removal; no send/removal time-of-check race.
        pairs.lockPair(actor,pair.other(actor.userId()),false);
        return chats.conversation(id);
    }
    private void requireVisible(ChatMessage message,long user) {
        if(chats.state(message.getId(),user).getDeletedForSelfAt()!=null) throw missing("Message",message.getId());
    }
    private MessageResponse response(ChatMessage m,Conversation c) { return mapper.message(m,chats.state(m.getId(),c.other(m.getSenderId()))); }
    private ResourceNotFoundException missing(String type,long id) { return new ResourceNotFoundException(type,id); }
    private void changed(Conversation c) { events.publishEvent(new ChatChanged(Set.of(c.getUserLow(),c.getUserHigh()))); }
    private LocalDateTime now() { return LocalDateTime.ofInstant(clock.instant(),ZoneOffset.UTC); }
}
