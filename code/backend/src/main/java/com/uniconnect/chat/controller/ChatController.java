package com.uniconnect.chat.controller;

import com.uniconnect.chat.dto.*;
import com.uniconnect.chat.service.ChatService;
import com.uniconnect.shared.dto.PageResponse;
import com.uniconnect.shared.security.SessionPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chat")
@Tag(name="One-to-one chat")
@SecurityRequirement(name="sessionBearer")
public class ChatController {
    private final ChatService chats;
    public ChatController(ChatService chats) { this.chats=chats; }
    @PostMapping("/messages")
    @Operation(summary="Send a text message to an accepted connection", description="Use a new clientMessageId UUID for each logical message; reuse it for retries. Returns the persisted message, including on a retry.")
    public ResponseEntity<MessageResponse> send(@AuthenticationPrincipal SessionPrincipal actor,@Valid @RequestBody SendMessageRequest request) {
        return ok(chats.send(actor,request));
    }
    @GetMapping("/conversations")
    @Operation(summary="List your conversations by latest message activity")
    public ResponseEntity<PageResponse<ConversationResponse>> list(@AuthenticationPrincipal SessionPrincipal actor,
            @RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="20") int size) {
        return ok(chats.list(actor,page,size));
    }
    @GetMapping("/conversations/{id}/messages")
    @Operation(summary="Open message history and mark returned incoming messages read", description="Newest page by default, returned in chronological order. Pass nextBeforeMessageId as beforeMessageId for older messages. Size: 1–50. History remains available after connection removal.")
    public ResponseEntity<HistoryResponse> history(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id,
            @RequestParam(required=false) Long beforeMessageId,@RequestParam(defaultValue="20") int size) {
        return ok(chats.history(actor,id,beforeMessageId,size));
    }
    @PatchMapping("/messages/{id}/delivered")
    @Operation(summary="Recipient acknowledges message delivery")
    public ResponseEntity<MessageResponse> delivered(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id) { return ok(chats.delivered(actor,id)); }
    @PatchMapping("/messages/{id}/read")
    @Operation(summary="Recipient marks a message read (also delivered)")
    public ResponseEntity<MessageResponse> read(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id) { return ok(chats.read(actor,id)); }
    @DeleteMapping("/messages/{id}/self")
    @Operation(summary="Hide a message from your own history")
    public ResponseEntity<Void> deleteForSelf(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id) {
        chats.deleteForSelf(actor,id); return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
    }
    @DeleteMapping("/messages/{id}/everyone")
    @Operation(summary="Sender hides message content for both participants", description="No time limit. Retains a tombstone and the underlying record.")
    public ResponseEntity<Void> deleteForEveryone(@AuthenticationPrincipal SessionPrincipal actor,@PathVariable long id) {
        chats.deleteForEveryone(actor,id); return ResponseEntity.noContent().cacheControl(CacheControl.noStore()).build();
    }
    private <T> ResponseEntity<T> ok(T body) { return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(body); }
}
