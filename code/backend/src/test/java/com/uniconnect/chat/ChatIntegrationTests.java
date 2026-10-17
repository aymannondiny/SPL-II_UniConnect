package com.uniconnect.chat;

import com.uniconnect.authentication.domain.User;
import com.uniconnect.authentication.dto.LoginRequest;
import com.uniconnect.authentication.repository.UserRepository;
import com.uniconnect.authentication.service.*;
import com.uniconnect.chat.dto.*;
import com.uniconnect.chat.service.ChatService;
import com.uniconnect.connection.dto.ConnectionRequest;
import com.uniconnect.connection.service.ConnectionService;
import com.uniconnect.shared.exception.*;
import com.uniconnect.shared.security.*;
import java.net.URI;
import java.net.http.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(webEnvironment=SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ChatIntegrationTests {
    @Autowired MockMvc mvc;
    @Autowired ChatService chats;
    @Autowired ConnectionService connections;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder passwords;
    @Autowired SessionService sessions;
    @Autowired ChatAccountService chatAccounts;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    @MockitoBean Clock clock;
    @LocalServerPort int port;
    private SessionPrincipal alice,bob,carol;
    private String aliceToken,bobToken,carolToken;
    private long connection;
    private static final Instant NOW=Instant.parse("2026-10-09T00:00:00Z");

    @BeforeEach
    void setup() {
        clean();
        when(clock.instant()).thenReturn(NOW);
        when(clock.getZone()).thenReturn(ZoneOffset.UTC);
        aliceToken=account("Alice"); bobToken=account("Bob"); carolToken=account("Carol");
        alice=sessions.authenticate(aliceToken); bob=sessions.authenticate(bobToken); carol=sessions.authenticate(carolToken);
        connection=connections.send(alice,new ConnectionRequest(bob.userId(),null)).id();
        connections.accept(bob,connection);
    }
    @AfterEach
    void clean() {
        for(String table:List.of("chat_message_states","chat_messages","chat_participants","chat_conversations",
                "notifications","connections","profile_skills","profile_interests","personal_profiles","skills","interests",
                "programme_degrees","programmes","departments","password_reset_tokens","email_verification_tokens","authenticated_sessions","users"))
            jdbc.update("delete from "+table);
    }
    private String account(String name) {
        var user=User.register(name,name.toLowerCase(Locale.ROOT)+"@iut-dhaka.edu",passwords.encode("password123"),PlatformRole.STUDENT);
        user.verifyEmail(LocalDateTime.ofInstant(NOW,ZoneOffset.UTC)); users.saveAndFlush(user);
        return sessions.login(new LoginRequest(user.getEmail(),"password123")).accessToken();
    }
    private SendMessageRequest request(SessionPrincipal receiver,String text) { return new SendMessageRequest(receiver.userId(),UUID.randomUUID(),text); }
    private MessageResponse send(String text) { return chats.send(alice,request(bob,text)); }
    private int count(String table) { return jdbc.queryForObject("select count(*) from "+table,Integer.class); }

    @Test
    void firstMessageAtomicallyCreatesPairAndStatesAndReverseSendReusesConversation() {
        assertThat(count("chat_conversations")).isZero();
        var first=send("Hello"); var reply=chats.send(bob,request(alice,"Hi"));
        assertThat(reply.conversationId()).isEqualTo(first.conversationId());
        assertThat(count("chat_conversations")).isEqualTo(1);
        assertThat(count("chat_participants")).isEqualTo(2);
        assertThat(count("chat_message_states")).isEqualTo(4);
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isEqualTo(1);
        assertThat(chats.list(alice,0,20).items().getFirst().latestVisibleMessage().content()).isEqualTo("Hi");
    }
    @Test
    void validationAndMissingConnectionLeaveNoPartialConversation() {
        assertThatThrownBy(() -> chats.send(alice,request(carol,"Hello"))).isInstanceOf(ForbiddenException.class);
        assertThatThrownBy(() -> chats.send(alice,request(alice,"Hello"))).isInstanceOf(BadRequestException.class);
        for(String text:List.of("", "   ","x".repeat(5001)))
            assertThatThrownBy(() -> send(text)).isInstanceOf(BadRequestException.class);
        assertThat(count("chat_conversations")).isZero();
        assertThat(send("x".repeat(5000)).content()).hasSize(5000);
    }
    @Test
    void pendingConnectionDoesNotAllowChat() {
        connections.send(alice,new ConnectionRequest(carol.userId(),null));
        assertThatThrownBy(() -> chats.send(alice,request(carol,"Hello"))).isInstanceOf(ForbiddenException.class);
        assertThat(count("chat_messages")).isZero();
    }
    @Test
    void retryIsIdempotentAndChangedContentConflicts() {
        var request=request(bob,"Hello"); var first=chats.send(alice,request);
        assertThat(chats.send(alice,request).id()).isEqualTo(first.id());
        assertThat(count("chat_messages")).isEqualTo(1);
        assertThatThrownBy(() -> chats.send(alice,new SendMessageRequest(bob.userId(),request.clientMessageId(),"Changed")))
                .isInstanceOf(ConflictException.class);
    }
    @Test
    void historyReadsOnlyReturnedMessagesAndCursorDoesNotSkipWithNewArrivals() {
        var one=send("one"); var two=send("two"); var three=send("three");
        var newest=chats.history(bob,one.conversationId(),null,2);
        assertThat(newest.items()).extracting(MessageResponse::id).containsExactly(two.id(),three.id());
        assertThat(newest.items()).allSatisfy(m -> { assertThat(m.readAt()).isNotNull(); assertThat(m.deliveredAt()).isNotNull(); });
        assertThat(newest.hasMore()).isTrue();
        assertThat(newest.nextBeforeMessageId()).isEqualTo(two.id());
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isEqualTo(1);
        send("four");
        var older=chats.history(bob,one.conversationId(),newest.nextBeforeMessageId(),2);
        assertThat(older.items()).extracting(MessageResponse::id).containsExactly(one.id());
        assertThat(older.hasMore()).isFalse(); assertThat(older.nextBeforeMessageId()).isNull();
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isEqualTo(1);
    }
    @Test
    void recipientOnlyReceiptsAreIdempotentAndReadingImpliesDelivery() {
        var message=send("Hello");
        assertThatThrownBy(() -> chats.delivered(alice,message.id())).isInstanceOf(ForbiddenException.class);
        var delivered=chats.delivered(bob,message.id());
        assertThat(delivered.deliveredAt()).isNotNull(); assertThat(delivered.readAt()).isNull();
        when(clock.instant()).thenReturn(NOW.plusSeconds(10));
        var read=chats.read(bob,message.id());
        assertThat(read.deliveredAt()).isEqualTo(delivered.deliveredAt());
        assertThat(read.readAt()).isAfter(read.deliveredAt());
        when(clock.instant()).thenReturn(NOW.plusSeconds(20));
        assertThat(chats.read(bob,message.id()).readAt()).isEqualTo(read.readAt());
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isZero();
    }
    @Test
    void selfDeletionIsPrivateAndEveryoneDeletionLeavesContentFreeTombstone() {
        var message=send("Private text");
        assertThatThrownBy(() -> chats.deleteForEveryone(bob,message.id())).isInstanceOf(ForbiddenException.class);
        chats.deleteForSelf(bob,message.id()); chats.deleteForSelf(bob,message.id());
        assertThat(chats.history(bob,message.conversationId(),null,20).items()).isEmpty();
        assertThat(chats.list(bob,0,20).items().getFirst().latestVisibleMessage()).isNull();
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isZero();
        assertThat(chats.history(alice,message.conversationId(),null,20).items().getFirst().content()).isEqualTo("Private text");
        assertThatThrownBy(() -> chats.read(bob,message.id())).isInstanceOf(ResourceNotFoundException.class);
        chats.deleteForEveryone(alice,message.id()); chats.deleteForEveryone(alice,message.id());
        var tombstone=chats.history(alice,message.conversationId(),null,20).items().getFirst();
        assertThat(tombstone.content()).isNull(); assertThat(tombstone.deletedForEveryoneAt()).isNotNull();
        assertThat(jdbc.queryForObject("select content from chat_messages where message_id=?",String.class,message.id())).isEqualTo("Private text");
        assertThat(chats.history(bob,message.conversationId(),null,20).items()).isEmpty();
    }
    @Test
    void senderCanDeleteForEveryoneAfterSelfDeletionAndRemoval() {
        var message=send("old text"); chats.deleteForSelf(alice,message.id()); connections.remove(bob,connection);
        chats.deleteForEveryone(alice,message.id());
        var result=chats.history(bob,message.conversationId(),null,20);
        assertThat(result.canSend()).isFalse(); assertThat(result.items().getFirst().content()).isNull();
        assertThat(chats.list(bob,0,20).items().getFirst().unreadCount()).isZero();
        assertThatThrownBy(() -> chats.read(bob,message.id())).isInstanceOf(ConflictException.class);
    }
    @Test
    void removalBlocksSendingRetainsHistoryAndReconnectionReusesConversation() {
        var first=send("Before removal"); connections.remove(alice,connection);
        assertThatThrownBy(() -> send("Blocked")).isInstanceOf(ForbiddenException.class);
        assertThat(chats.history(bob,first.conversationId(),null,20).items()).hasSize(1);
        assertThat(chats.list(alice,0,20).items().getFirst().canSend()).isFalse();
        long reconnected=connections.send(bob,new ConnectionRequest(alice.userId(),null)).id(); connections.accept(alice,reconnected);
        assertThat(send("Back again").conversationId()).isEqualTo(first.conversationId());
        assertThat(count("chat_conversations")).isEqualTo(1);
    }
    @Test
    void nonparticipantsCannotReadAcknowledgeOrDeleteEvenWithKnownIds() {
        var message=send("secret");
        assertThat(chats.list(carol,0,20).totalElements()).isZero();
        assertThatThrownBy(() -> chats.history(carol,message.conversationId(),null,20)).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> chats.read(carol,message.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> chats.delivered(carol,message.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> chats.deleteForSelf(carol,message.id())).isInstanceOf(ResourceNotFoundException.class);
        assertThatThrownBy(() -> chats.deleteForEveryone(carol,message.id())).isInstanceOf(ResourceNotFoundException.class);
    }
    @Test
    void inactivePeerBlocksNewMessagesButParticipantKeepsHistory() {
        var first=send("History"); jdbc.update("update users set account_status='SUSPENDED' where user_id=?",bob.userId());
        assertThatThrownBy(() -> send("Blocked")).isInstanceOf(ResourceNotFoundException.class);
        assertThat(chats.history(alice,first.conversationId(),null,20).canSend()).isFalse();
        assertThatThrownBy(() -> chats.list(bob,0,20)).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void revokedOrExpiredSessionCannotAccessChatOrSockets() {
        var identity=chatAccounts.authenticateSocket(aliceToken);
        sessions.logout(alice);
        assertThatThrownBy(() -> send("Blocked")).isInstanceOf(InvalidSessionException.class);
        assertThatThrownBy(() -> chatAccounts.validateLiveSession(identity)).isInstanceOf(InvalidSessionException.class);
        when(clock.instant()).thenReturn(NOW.plusSeconds(901));
        assertThatThrownBy(() -> chats.list(bob,0,20)).isInstanceOf(InvalidSessionException.class);
    }
    @Test
    void tokenRefreshInvalidatesOldSocketIdentity() {
        var login=sessions.login(new LoginRequest("alice@iut-dhaka.edu","password123"));
        var old=chatAccounts.authenticateSocket(login.accessToken());
        var fresh=sessions.refresh(login.refreshToken());
        assertThatThrownBy(() -> chatAccounts.validateLiveSession(old)).isInstanceOf(InvalidSessionException.class);
        chatAccounts.validateLiveSession(chatAccounts.authenticateSocket(fresh.accessToken()));
    }
    @Test
    void simultaneousFirstMessagesCreateOnlyOneConversation() throws Exception {
        var start=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            var a=pool.submit(() -> { start.await(); return send("Alice"); });
            var b=pool.submit(() -> { start.await(); return chats.send(bob,request(alice,"Bob")); });
            start.countDown();
            assertThat(a.get(15,TimeUnit.SECONDS).conversationId()).isEqualTo(b.get(15,TimeUnit.SECONDS).conversationId());
        }
        assertThat(count("chat_conversations")).isEqualTo(1); assertThat(count("chat_messages")).isEqualTo(2);
        assertThat(count("chat_participants")).isEqualTo(2); assertThat(count("chat_message_states")).isEqualTo(4);
    }
    @Test
    void simultaneousRetriesStoreOneMessage() throws Exception {
        var request=request(bob,"One logical message"); var start=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            var a=pool.submit(() -> { start.await(); return chats.send(alice,request); });
            var b=pool.submit(() -> { start.await(); return chats.send(alice,request); }); start.countDown();
            assertThat(a.get(15,TimeUnit.SECONDS).id()).isEqualTo(b.get(15,TimeUnit.SECONDS).id());
        }
        assertThat(count("chat_messages")).isEqualTo(1);
    }
    @Test
    void sendAndRemovalSerializeAndAllLaterSendsAreBlocked() throws Exception {
        var start=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            var sending=pool.submit(() -> {
                start.await();
                try { send("racing send"); return true; } catch(ForbiddenException expected) { return false; }
            });
            var removing=pool.submit(() -> { start.await(); connections.remove(bob,connection); return true; });
            start.countDown();
            boolean sent=sending.get(15,TimeUnit.SECONDS); removing.get(15,TimeUnit.SECONDS);
            assertThat(count("chat_messages")).isEqualTo(sent?1:0);
        }
        assertThatThrownBy(() -> send("after removal")).isInstanceOf(ForbiddenException.class);
    }
    @Test
    void outerRollbackLeavesNoConversationOrMessage() {
        new TransactionTemplate(transactions).executeWithoutResult(status -> { send("rolled back"); status.setRollbackOnly(); });
        assertThat(count("chat_conversations")).isZero(); assertThat(count("chat_messages")).isZero();
        assertThat(count("chat_participants")).isZero(); assertThat(count("chat_message_states")).isZero();
    }
    @Test
    void restRequiresAuthenticationValidatesInputsAndHidesOtherConversations() throws Exception {
        mvc.perform(get("/api/v1/chat/conversations")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/chat/messages").header("Authorization","Bearer "+aliceToken)
                .contentType("application/json").content("{}")) .andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/chat/conversations?size=51").header("Authorization","Bearer "+aliceToken)).andExpect(status().isBadRequest());
        var message=send("Hello");
        mvc.perform(get("/api/v1/chat/conversations/"+message.conversationId()+"/messages").header("Authorization","Bearer "+carolToken)).andExpect(status().isNotFound());
        mvc.perform(get("/api/v1/chat/conversations/"+message.conversationId()+"/messages").header("Authorization","Bearer "+bobToken))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control","no-store"))
                .andExpect(jsonPath("$.items[0].content").value("Hello")).andExpect(jsonPath("$.items[0].readAt").exists());
        mvc.perform(delete("/api/v1/chat/messages/"+message.id()+"/everyone").header("Authorization","Bearer "+aliceToken)).andExpect(status().isNoContent());
    }
    @Test
    void websocketDeliversOnlyCommittedParticipantInvalidations() throws Exception {
        var received=new LinkedBlockingQueue<String>(); var stranger=new LinkedBlockingQueue<String>();
        try(var client=HttpClient.newHttpClient()) {
            var bobSocket=connect(client,bobToken,received); var carolSocket=connect(client,carolToken,stranger);
            try {
                assertThat(received.poll(5,TimeUnit.SECONDS)).isEqualTo("{\"type\":\"READY\"}");
                assertThat(stranger.poll(5,TimeUnit.SECONDS)).isEqualTo("{\"type\":\"READY\"}");
                new TransactionTemplate(transactions).executeWithoutResult(status -> { send("rollback"); status.setRollbackOnly(); });
                assertThat(received.poll(300,TimeUnit.MILLISECONDS)).isNull();
                send("Do not include this content in events");
                assertThat(received.poll(5,TimeUnit.SECONDS)).isEqualTo("{\"type\":\"CHAT_CHANGED\"}");
                assertThat(stranger.poll(300,TimeUnit.MILLISECONDS)).isNull();
            } finally { bobSocket.abort(); carolSocket.abort(); }
        }
    }
    @Test
    void websocketRejectsUnapprovedOrigin() {
        try(var client=HttpClient.newHttpClient()) {
            assertThatThrownBy(() -> client.newWebSocketBuilder().header("Origin","https://untrusted.example")
                    .buildAsync(URI.create("ws://localhost:"+port+"/ws/chat"),new WebSocket.Listener() {}).join())
                    .hasCauseInstanceOf(WebSocketHandshakeException.class);
        }
    }
    private WebSocket connect(HttpClient client,String token,BlockingQueue<String> received) {
        var socket=client.newWebSocketBuilder().header("Origin","http://localhost:8080")
                .buildAsync(URI.create("ws://localhost:"+port+"/ws/chat"),new WebSocket.Listener() {
                    private final StringBuilder text=new StringBuilder();
                    @Override public void onOpen(WebSocket ws) { ws.request(1); }
                    @Override public CompletionStage<?> onText(WebSocket ws,CharSequence data,boolean last) {
                        text.append(data); if(last) { received.add(text.toString()); text.setLength(0); }
                        ws.request(1); return null;
                    }
                }).join();
        socket.sendText("AUTH "+token,true).join(); return socket;
    }
}
