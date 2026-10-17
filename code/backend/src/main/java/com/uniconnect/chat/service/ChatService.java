package com.uniconnect.chat.service;
import com.uniconnect.authentication.service.*;
import com.uniconnect.chat.domain.*;
import com.uniconnect.chat.dto.*;
import com.uniconnect.chat.mapper.ChatMapper;
import com.uniconnect.chat.repository.ChatRepository;
import com.uniconnect.connection.service.ConnectionQueryService;
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
    private final ChatRepository chats;
    private final MemberAccountService pairs;
    private final ProfileAccountService accounts;
    private final ChatAccountService accountDetails;
    private final ConnectionQueryService connections;
    private final ChatMapper mapper;
    private final Validator validator;
    private final Clock clock;
    private final ApplicationEventPublisher events;
    public ChatService(ChatRepository chats,MemberAccountService pairs,ProfileAccountService accounts,
            ChatAccountService accountDetails,ConnectionQueryService connections,ChatMapper mapper,
            Validator validator,Clock clock,ApplicationEventPublisher events) {
        this.chats=chats; this.pairs=pairs; this.accounts=accounts; this.accountDetails=accountDetails;
        this.connections=connections; this.mapper=mapper; this.validator=validator; this.clock=clock; this.events=events;
    }
    public MessageResponse send(SessionPrincipal actor,SendMessageRequest request) {
        if(request==null || !validator.validate(request).isEmpty()) throw new BadRequestException("INVALID_MESSAGE","Message requires a receiver, client UUID, and 1–5000 nonblank characters.");
        pairs.lockPair(actor,request.receiverId(),true);
        if(!connections.areAccepted(actor.userId(),request.receiverId())) throw new ForbiddenException("An accepted connection is required to send messages.");
        var existing=chats.clientMessage(actor.userId(),request.clientMessageId());
        if(existing.isPresent()) {
            var m=existing.get(); var c=chats.conversation(m.getConversationId());
            if(c.other(actor.userId())!=request.receiverId() || !m.getContent().equals(request.content()))
                throw new ConflictException("MESSAGE_RETRY_CONFLICT","This clientMessageId was used for a different message.");
            requireVisible(m,actor.userId());
            return response(m,c);
        }
        var now=now();
        var conversation=chats.findPair(Math.min(actor.userId(),request.receiverId()),Math.max(actor.userId(),request.receiverId())).orElse(null);
        if(conversation==null) {
            conversation=chats.insert(new Conversation(actor.userId(),request.receiverId(),now));
            chats.insert(new ConversationParticipant(conversation.getId(),conversation.getUserLow(),1,now));
            chats.insert(new ConversationParticipant(conversation.getId(),conversation.getUserHigh(),2,now));
        }
        var message=chats.insert(new ChatMessage(conversation.getId(),actor.userId(),request.clientMessageId(),request.content(),now));
        chats.insert(new MessageParticipantState(message.getId(),conversation.getId(),conversation.getUserLow()));
        chats.insert(new MessageParticipantState(message.getId(),conversation.getId(),conversation.getUserHigh()));
        conversation.messageSent(now);
        changed(conversation);
        return response(message,conversation);
    }
    public PageResponse<ConversationResponse> list(SessionPrincipal actor,int page,int size) {
        accounts.lockActiveAccount(actor);
        PageValidation.check(page,size);
        var items=chats.conversations(actor.userId(),page,size).stream().map(c -> {
            var other=accountDetails.summary(c.other(actor.userId()));
            var latest=chats.visible(c.getId(),actor.userId(),null,1);
            return new ConversationResponse(c.getId(),c.other(actor.userId()),other.name(),other.active() && connections.areAccepted(actor.userId(),c.other(actor.userId())),
                    c.getCreatedAt(),c.getLastMessageAt(),latest.isEmpty()?null:response(latest.getFirst(),c),chats.unread(c.getId(),actor.userId()));
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
        boolean updated=false;
        for(var m:messages) if(!m.getSenderId().equals(actor.userId()) && m.getDeletedForEveryoneAt()==null)
            updated=chats.state(m.getId(),actor.userId()).read(now()) || updated;
        if(updated) changed(c);
        Collections.reverse(messages);
        boolean canSend=accountDetails.summary(c.other(actor.userId())).active() && connections.areAccepted(actor.userId(),c.other(actor.userId()));
        return new HistoryResponse(c.getId(),canSend,messages.stream().map(m -> response(m,c)).toList(),more,next);
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
