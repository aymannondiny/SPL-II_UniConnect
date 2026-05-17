-- ================================================
-- V7: Chat Module Tables
-- ================================================

-- Conversations
CREATE TABLE conversations (
                               conversation_id SERIAL PRIMARY KEY,
                               created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_conversations_created ON conversations(created_at);

-- Conversation Participants (Junction Table)
CREATE TABLE conversation_participants (
                                           participant_id SERIAL PRIMARY KEY,
                                           conversation_id INTEGER NOT NULL REFERENCES conversations(conversation_id) ON DELETE CASCADE,
                                           user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                           joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                           UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conversation_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_user ON conversation_participants(user_id);

-- Messages
CREATE TABLE messages (
                          message_id SERIAL PRIMARY KEY,
                          conversation_id INTEGER NOT NULL REFERENCES conversations(conversation_id) ON DELETE CASCADE,
                          sender_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                          content TEXT NOT NULL CHECK (LENGTH(content) >= 1 AND LENGTH(content) <= 5000),
                          sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          read_at TIMESTAMP
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_sent_at ON messages(sent_at);
CREATE INDEX idx_messages_conversation_sent ON messages(conversation_id, sent_at);