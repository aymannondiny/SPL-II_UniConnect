package com.uniconnect.chat;

import com.uniconnect.authentication.service.ChatAccountService;
import com.uniconnect.authentication.service.ChatAccountService.SocketIdentity;
import com.uniconnect.authentication.service.InvalidSessionException;
import com.uniconnect.chat.realtime.ChatSocketHandler;
import com.uniconnect.chat.service.ChatChanged;
import com.uniconnect.shared.security.*;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.web.socket.*;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ChatSocketHandlerTests {
    private ChatAccountService accounts;
    private ChatSocketHandler handler;
    private WebSocketSession socket;
    private Clock clock;
    private SocketIdentity identity;
    private static final String TOKEN="a".repeat(43);
    private static final Instant NOW=Instant.parse("2026-10-09T00:00:00Z");
    @BeforeEach
    void setup() throws Exception {
        accounts=mock(ChatAccountService.class); clock=mock(Clock.class);
        when(clock.instant()).thenReturn(NOW);
        identity=new SocketIdentity(new SessionPrincipal(UUID.randomUUID(),2L,PlatformRole.STUDENT),"hash");
        when(accounts.authenticateSocket(TOKEN)).thenReturn(identity);
        handler=new ChatSocketHandler(accounts,clock); socket=socket("one");
        handler.afterConnectionEstablished(socket);
    }
    private WebSocketSession socket(String id) {
        var s=mock(WebSocketSession.class); when(s.getId()).thenReturn(id); when(s.isOpen()).thenReturn(true); return s;
    }
    private void authenticate() throws Exception { handler.handleMessage(socket,new TextMessage("AUTH "+TOKEN)); }
    @Test
    void unauthenticatedSocketGetsNoEventsAndInvalidFrameClosesIt() throws Exception {
        handler.changed(new ChatChanged(Set.of(2L))); handler.flushChanges();
        verify(socket,never()).sendMessage(any());
        handler.handleMessage(socket,new TextMessage("PING"));
        verify(socket).close(argThat(s -> s.getCode()==1008));
        verifyNoInteractions(accounts);
    }
    @Test
    void authenticatedEventsAreCoalescedAndNeverContainMessageData() throws Exception {
        authenticate();
        verify(socket).sendMessage(argThat(m -> m.getPayload().equals("{\"type\":\"READY\"}")));
        handler.changed(new ChatChanged(Set.of(3L))); handler.flushChanges();
        verify(socket,times(1)).sendMessage(any());
        handler.changed(new ChatChanged(Set.of(2L))); handler.changed(new ChatChanged(Set.of(2L))); handler.flushChanges(); handler.flushChanges();
        verify(socket,times(2)).sendMessage(any());
        verify(socket).sendMessage(argThat(m -> m.getPayload().equals("{\"type\":\"CHAT_CHANGED\"}")));
        verify(accounts,times(2)).validateLiveSession(identity);
    }
    @Test
    void invalidatedSessionClosesBeforeSendingAnEvent() throws Exception {
        authenticate(); doThrow(new InvalidSessionException()).when(accounts).validateLiveSession(identity);
        handler.changed(new ChatChanged(Set.of(2L))); handler.flushChanges();
        verify(socket,times(1)).sendMessage(any()); verify(socket).close(argThat(s -> s.getCode()==1008));
    }
    @Test
    void unauthenticatedSocketTimesOut() throws Exception {
        when(clock.instant()).thenReturn(NOW.plusSeconds(11)); handler.expireSessions();
        verify(socket).close(argThat(s -> s.getCode()==1008)); verifyNoInteractions(accounts);
    }
    @Test
    void idleAuthenticatedSocketIsRevalidated() throws Exception {
        authenticate(); doThrow(new InvalidSessionException()).when(accounts).validateLiveSession(identity);
        handler.expireSessions(); verify(socket).close(argThat(s -> s.getCode()==1008));
    }
    @Test
    void sixthSocketForSameUserIsRejected() throws Exception {
        authenticate();
        for(int i=2;i<=5;i++) {
            var another=socket("socket-"+i); handler.afterConnectionEstablished(another);
            handler.handleMessage(another,new TextMessage("AUTH "+TOKEN));
        }
        var sixth=socket("sixth"); handler.afterConnectionEstablished(sixth); handler.handleMessage(sixth,new TextMessage("AUTH "+TOKEN));
        verify(sixth).close(argThat(s -> s.getCode()==1008)); verify(sixth,never()).sendMessage(any());
    }
    @Test
    void socketFailuresCannotFailCommittedWrites() throws Exception {
        authenticate(); doThrow(new java.io.IOException("Disconnected")).when(socket).sendMessage(any());
        handler.changed(new ChatChanged(Set.of(2L))); handler.flushChanges();
        verify(socket).close(argThat(s -> s.getCode()==1008));
    }
}
