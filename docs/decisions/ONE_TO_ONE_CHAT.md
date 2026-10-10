# One-to-one chat persistence and transport

## Context

The corrected chat model requires a single unordered-pair conversation, two participants, per-message delivery/read/self-deletion state, retained history after connection removal, and sender-controlled everyone deletion. Ordinary messages are distinct from connection introductions.

## Decisions

- Use Flyway V8 and a separate chat module. Authentication and connection eligibility are consulted through their service APIs, without accessing another module's repositories.
- Use the existing ascending account-row lock order for sends, receipts, history reads, and deletions. This serializes opposite first sends, retries, and connection removal. Resolve IDs with scalar projections before acquiring locks, so JPA does not cache stale conversation/message state while waiting.
- Persist pair, participants, first message, and both state records in one transaction. Unique pair and sender/client-UUID constraints supplement service checks. Participant slots cap membership at two. Foreign keys restrict senders and state owners to conversation participants.
- Add a client-generated UUID per logical send for safe retries. A repeated UUID with different content/receiver is a conflict. IDs order history within a conversation; keyset pagination avoids offset skips when new messages arrive.
- Keep receipt and deletion state server-authoritative. Read implies delivered. History access marks only returned incoming visible content read. Self deletion is private; everyone deletion masks content in every public message mapping without destroying evidence.
- Use REST for persisted operations and authenticated WebSocket invalidations for live updates. The browser sends AUTH in the first frame, avoiding credential-bearing URLs. The server stores only a token hash and revalidates it before every outbound event and during idle sweeps, including after token rotation.
- Publish invalidations only after commit, coalesce them per connected client, and drain them outside HTTP transactions. No socket I/O or additional database connection is required inside an after-commit callback. Broken sockets cannot roll back a saved message.
- Send no message content over the socket. Clients refetch authorized state on READY, change, and reconnect. Events can be dropped across disconnects; the database is authoritative. This implementation targets a single backend instance; multiple instances require a shared event broker.

## Scope

This implements the chat backend and its transport contract. Flutter screens, reporting/moderation workflows, typing indicators, attachments, presence, and multi-instance event distribution remain separate tasks. Existing connection notifications remain unchanged; a chat invalidation is not an in-app notification record.
