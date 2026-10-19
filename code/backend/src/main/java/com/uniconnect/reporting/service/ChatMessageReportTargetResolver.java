package com.uniconnect.reporting.service;
import com.uniconnect.chat.service.ChatService;
import com.uniconnect.reporting.domain.ReportTargetType;
import com.uniconnect.shared.security.SessionPrincipal;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;
@Component
public class ChatMessageReportTargetResolver implements ReportTargetResolver {
    private final ChatService chats;private final JsonMapper json;
    public ChatMessageReportTargetResolver(ChatService chats,JsonMapper json){this.chats=chats;this.json=json;}
    public boolean supports(ReportTargetType type){return type==ReportTargetType.CHAT_MESSAGE;}
    public ReportTargetEvidence resolve(SessionPrincipal actor,ReportTargetType type,long id){var m=chats.reportableMessage(actor,id);
        return new ReportTargetEvidence("Chat message "+id,json.writeValueAsString(m),m.senderId(),null);}
}
