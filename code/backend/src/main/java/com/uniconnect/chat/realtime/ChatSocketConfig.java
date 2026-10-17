package com.uniconnect.chat.realtime;

import java.util.Arrays;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocket
@EnableScheduling
public class ChatSocketConfig implements WebSocketConfigurer {
    private final ChatSocketHandler handler;
    private final String[] origins;
    public ChatSocketConfig(ChatSocketHandler handler,
            @Value("${uniconnect.chat.allowed-origins:http://localhost:8080,http://localhost:3000}") String origins) {
        this.handler=handler;
        this.origins=Arrays.stream(origins.split(",")).map(String::trim).filter(s -> !s.isEmpty()).toArray(String[]::new);
        if(this.origins.length==0 || Arrays.stream(this.origins).anyMatch(s -> s.contains("*")))
            throw new IllegalArgumentException("Chat requires explicit allowed origins");
    }
    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler,"/ws/chat").setAllowedOrigins(origins);
    }
}
