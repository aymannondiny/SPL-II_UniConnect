package com.uniconnect.chat.service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/** Opt-in send-path timings. Never records message content, identities, or credentials. */
@Component
public class ChatPerformanceDiagnostics {
    private static final Logger LOG = LoggerFactory.getLogger(ChatPerformanceDiagnostics.class);
    private final boolean enabled;

    public ChatPerformanceDiagnostics(@Value("${uniconnect.chat.performance-logging:false}") boolean enabled) {
        this.enabled = enabled;
    }

    public Trace start(UUID clientMessageId) {
        return new Trace(enabled, clientMessageId);
    }

    public static final class Trace {
        private final boolean enabled;
        private final UUID correlationId;
        private final long started;
        private long previous;
        private final List<String> phases = new ArrayList<>();

        private Trace(boolean enabled, UUID correlationId) {
            this.enabled = enabled;
            this.correlationId = correlationId;
            this.started = enabled ? System.nanoTime() : 0;
            this.previous = started;
        }

        public void mark(String phase) {
            if (!enabled) return;
            long now = System.nanoTime();
            phases.add(phase + "=" + elapsedMillis(previous, now) + "ms");
            previous = now;
        }

        public void finishAfterCommit(String outcome) {
            if (!enabled) return;
            if (TransactionSynchronizationManager.isSynchronizationActive()) {
                TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        finish(outcome);
                    }
                });
                return;
            }
            finish(outcome);
        }

        private void finish(String outcome) {
            long now = System.nanoTime();
            LOG.info("chat_send correlation={} outcome={} total={}ms phases=[{}]",
                    correlationId, outcome, elapsedMillis(started, now), String.join(",", phases));
        }

        private static long elapsedMillis(long from, long to) {
            return Math.max(0, (to - from) / 1_000_000);
        }
    }
}
