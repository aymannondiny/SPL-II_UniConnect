package com.uniconnect.chat.realtime;

import com.uniconnect.authentication.service.ChatAccountService;
import com.uniconnect.authentication.service.ChatAccountService.SocketIdentity;
import com.uniconnect.chat.service.ChatChanged;
import java.util.concurrent.atomic.AtomicBoolean;
import java.io.IOException;
import java.time.Clock;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.socket.*;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;

/** Content-free invalidations: REST remains the only authority for chat data and writes. */
@Component
public class ChatSocketHandler extends TextWebSocketHandler {
    private static final CloseStatus DENIED=new CloseStatus(1008,"Authentication required or session expired");
    private final ConcurrentHashMap<String,Client> clients=new ConcurrentHashMap<>();
    private final ChatAccountService accounts;
    private final Clock clock;
    private static final class Client {
        final WebSocketSession socket;
        final long openedAt;
        volatile SocketIdentity identity;
        final AtomicBoolean dirty=new AtomicBoolean();
        Client(WebSocketSession socket,long openedAt) {
            this.socket=new ConcurrentWebSocketSessionDecorator(socket,5000,4096);
            this.openedAt=openedAt;
        }
    }
    public ChatSocketHandler(ChatAccountService accounts,Clock clock) {
        this.accounts=accounts; this.clock=clock;
    }
    @Override
    public synchronized void afterConnectionEstablished(WebSocketSession socket) throws IOException {
        if(clients.size()>=1000) { socket.close(CloseStatus.POLICY_VIOLATION); return; }
        socket.setTextMessageSizeLimit(128);
        socket.setBinaryMessageSizeLimit(128);
        clients.put(socket.getId(),new Client(socket,clock.instant().toEpochMilli()));
    }
    @Override
    protected void handleTextMessage(WebSocketSession socket,TextMessage message) {
        var client=clients.get(socket.getId());
        if(client==null) return;
        try {
            if(client.identity==null) {
                String payload=message.getPayload();
                if(clock.instant().toEpochMilli()-client.openedAt>10000 || !payload.matches("AUTH [A-Za-z0-9_-]{43}")) { close(client); return; }
                var identity=accounts.authenticateSocket(payload.substring(5));
                synchronized(this) {
                    long count=clients.values().stream().filter(c -> c.identity!=null && c.identity.actor().userId().equals(identity.actor().userId())).count();
                    if(count>=5) { close(client); return; }
                    client.identity=identity;
                }
                send(client,"READY");
            } else if("PING".equals(message.getPayload())) {
                send(client,"PONG");
            } else close(client);
        } catch(RuntimeException failure) { close(client); }
    }
    @TransactionalEventListener(phase=TransactionPhase.AFTER_COMMIT)
    public void changed(ChatChanged event) {
        for(var client:clients.values()) {
            var identity=client.identity;
            if(identity!=null && event.userIds().contains(identity.actor().userId())) client.dirty.set(true);
        }
    }
    // Coalesce after-commit events; never hold an HTTP transaction while doing socket I/O.
    @Scheduled(fixedDelay=100)
    public void flushChanges() {
        for(var client:clients.values()) if(client.dirty.getAndSet(false)) send(client,"CHAT_CHANGED");
    }
    private void send(Client client,String type) {
        try {
            accounts.validateLiveSession(client.identity);
            client.socket.sendMessage(new TextMessage("{\"type\":\""+type+"\"}"));
        } catch(RuntimeException | IOException failure) { close(client); }
    }
    @Scheduled(fixedDelay=5000)
    public void expireSessions() {
        for(var client:clients.values()) {
            try {
                if(client.identity==null) {
                    if(clock.instant().toEpochMilli()-client.openedAt>=10000) close(client);
                } else accounts.validateLiveSession(client.identity);
            } catch(RuntimeException failure) { close(client); }
        }
    }
    @Override
    public void afterConnectionClosed(WebSocketSession socket,CloseStatus status) { clients.remove(socket.getId()); }
    @Override
    public void handleTransportError(WebSocketSession socket,Throwable error) {
        var client=clients.get(socket.getId()); if(client!=null) close(client);
    }
    private void close(Client client) {
        clients.remove(client.socket.getId(),client);
        try { client.socket.close(DENIED); } catch(IOException | RuntimeException ignored) { /* Already closed. */ }
    }
}
