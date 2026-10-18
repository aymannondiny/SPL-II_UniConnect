import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/data/chat_socket_contract.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.sessionController, this.repository, super.key});

  final SessionController sessionController;
  final ChatRepository? repository;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ApiClient _client;
  late final ChatRepository _repository;
  final _search = TextEditingController();
  final _composer = TextEditingController();
  final _messageList = ScrollController();
  final _pageKey = GlobalKey<ScaffoldMessengerState>();
  final List<ChatMessage> _messages = [];
  final Set<int> _deliveryAcknowledgements = {};
  List<ChatConversation> _conversations = [];
  ChatConversation? _selected;
  ChatConnection? _draftConnection;
  bool _loadingInbox = true;
  bool _inboxRequestActive = false;
  bool _loadingHistory = false;
  bool _loadingOlder = false;
  bool _sending = false;
  bool _hasMore = false;
  int? _nextBeforeId;
  String? _error;
  String? _retryMessageId;
  String? _retryContent;
  int? _retryRecipientId;
  int _historyRequestGeneration = 0;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription<String>? _socketSubscription;
  ChatSocketConnection? _socket;
  String? _socketToken;
  int _reconnectCount = 0;
  bool _showThread = false;

  String? get _token => widget.sessionController.currentAccessToken;
  int? get _myUserId => widget.sessionController.account?.userId;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _repository = widget.repository ?? ChatRepository(_client);
    widget.sessionController.addListener(_sessionChanged);
    _refreshInbox();
    _connectSocket();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      _refreshInbox(quiet: true);
      final selected = _selected;
      if (selected != null && _showThread) {
        _loadHistory(selected, quiet: true);
      }
    });
  }

  @override
  void dispose() {
    widget.sessionController.removeListener(_sessionChanged);
    _pollTimer?.cancel();
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    _client.close();
    _search.dispose();
    _composer.dispose();
    _messageList.dispose();
    super.dispose();
  }

  void _sessionChanged() {
    final token = _token;
    if (token == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (token != _socketToken) _connectSocket();
  }

  Future<void> _connectSocket() async {
    final token = _token;
    if (!mounted || token == null) return;
    _reconnectTimer?.cancel();
    await _socketSubscription?.cancel();
    await _socket?.close();
    try {
      final socket = await _repository.connect(token);
      if (!mounted || token != _token) {
        await socket.close();
        return;
      }
      _socket = socket;
      _socketToken = token;
      _reconnectCount = 0;
      _socketSubscription = socket.messages.listen(
        (event) {
          try {
            final decoded = jsonDecode(event) as Map<String, dynamic>;
            final type = decoded['type'];
            if (type == 'READY' || type == 'CHAT_CHANGED') {
              _refreshInbox(quiet: true);
              final selected = _selected;
              if (selected != null && _showThread) {
                _loadHistory(selected, quiet: true);
              }
            }
          } on Object {
            // Ignore malformed hints; REST remains the source of truth.
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (_socketToken == _token) _socket?.send('PING');
      });
    } on Object {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!mounted || _token == null || _reconnectTimer?.isActive == true) return;
    _pingTimer?.cancel();
    _socketToken = null;
    final seconds = math.min(30, math.pow(2, _reconnectCount).toInt());
    _reconnectCount = math.min(_reconnectCount + 1, 5);
    _reconnectTimer = Timer(Duration(seconds: seconds), _connectSocket);
  }

  Future<void> _refreshInbox({bool quiet = false}) async {
    final token = _token;
    if (token == null || _inboxRequestActive) return;
    _inboxRequestActive = true;
    if (!quiet && mounted) setState(() => _loadingInbox = true);
    try {
      final rows = await _repository.conversations(token);
      if (!mounted) return;
      ChatConversation? firstConversationToOpen;
      setState(() {
        _conversations = rows;
        _loadingInbox = false;
        _error = null;
        if (_selected == null &&
            rows.isNotEmpty &&
            MediaQuery.sizeOf(context).width >= 1240) {
          firstConversationToOpen = rows.first;
          _selected = rows.first;
          _showThread = true;
        }
        if (_selected != null) {
          final updated = rows.where((item) => item.id == _selected!.id);
          if (updated.isNotEmpty) _selected = updated.first;
        }
      });
      if (firstConversationToOpen != null) {
        unawaited(_loadHistory(firstConversationToOpen!));
      }
      for (final conversation in rows) {
        final latest = conversation.latestVisibleMessage;
        if (latest != null &&
            latest.senderId != _myUserId &&
            latest.content != null &&
            latest.deliveredAt == null &&
            latest.readAt == null) {
          unawaited(_acknowledgeDelivery(latest));
        }
      }
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingInbox = false;
        if (!quiet) _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    } finally {
      _inboxRequestActive = false;
    }
  }

  Future<void> _loadHistory(
    ChatConversation conversation, {
    bool quiet = false,
  }) async {
    final token = _token;
    if (token == null) return;
    final requestGeneration = ++_historyRequestGeneration;
    if (mounted) {
      setState(() {
        _loadingHistory = true;
        if (!quiet) _error = null;
      });
    }
    try {
      final result = await _repository.history(token, conversation.id);
      if (!mounted) return;
      if (requestGeneration != _historyRequestGeneration ||
          _selected?.id != conversation.id) {
        if (requestGeneration == _historyRequestGeneration) {
          setState(() => _loadingHistory = false);
        }
        return;
      }
      setState(() {
        if (quiet) {
          // A quiet refresh fetches the newest page, but the user may already
          // have loaded older pages. Keep that paging cursor so the next
          // "Load older messages" request continues from the oldest message
          // currently shown instead of fetching the newest page again.
          final preservePagination = _messages.isNotEmpty;
          final hasMore = _hasMore;
          final nextBeforeId = _nextBeforeId;
          final byId = {for (final message in _messages) message.id: message};
          for (final message in result.items) {
            byId[message.id] = message;
          }
          _messages
            ..clear()
            ..addAll(
              byId.values.toList()..sort((a, b) {
                final byTime = a.sentAt.compareTo(b.sentAt);
                return byTime != 0 ? byTime : a.id.compareTo(b.id);
              }),
            );
          _hasMore = preservePagination ? hasMore : result.hasMore;
          _nextBeforeId = preservePagination
              ? nextBeforeId
              : result.nextBeforeMessageId;
        } else {
          _messages
            ..clear()
            ..addAll(result.items);
          _hasMore = result.hasMore;
          _nextBeforeId = result.nextBeforeMessageId;
        }
        _loadingHistory = false;
        _error = null;
      });
      _refreshInbox(quiet: true);
      if (!quiet) _scrollToLatest();
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      if (requestGeneration != _historyRequestGeneration) return;
      setState(() {
        _loadingHistory = false;
        if (!quiet) _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    }
  }

  Future<void> _acknowledgeDelivery(ChatMessage message) async {
    if (!_deliveryAcknowledgements.add(message.id)) return;
    final token = _token;
    if (token == null) {
      _deliveryAcknowledgements.remove(message.id);
      return;
    }
    try {
      final updated = await _repository.acknowledgeDelivered(token, message.id);
      if (!mounted) return;
      setState(() {
        _conversations = _conversations
            .map((conversation) {
              if (conversation.latestVisibleMessage?.id != updated.id) {
                return conversation;
              }
              return ChatConversation(
                id: conversation.id,
                otherUserId: conversation.otherUserId,
                otherFullName: conversation.otherFullName,
                canSend: conversation.canSend,
                unreadCount: conversation.unreadCount,
                lastMessageAt: conversation.lastMessageAt,
                latestVisibleMessage: updated,
              );
            })
            .toList(growable: false);
        final index = _messages.indexWhere((item) => item.id == updated.id);
        if (index >= 0) _messages[index] = updated;
      });
    } on ChatFailure catch (failure) {
      _deliveryAcknowledgements.remove(message.id);
      if (failure.sessionEnded) _expireSession();
    } on Object {
      _deliveryAcknowledgements.remove(message.id);
    }
  }

  Future<void> _loadOlder() async {
    final conversation = _selected;
    final token = _token;
    final before = _nextBeforeId;
    if (conversation == null ||
        token == null ||
        before == null ||
        _loadingOlder) {
      return;
    }
    setState(() => _loadingOlder = true);
    try {
      final result = await _repository.history(
        token,
        conversation.id,
        beforeMessageId: before,
      );
      if (!mounted || _selected?.id != conversation.id) return;
      setState(() {
        final known = _messages.map((item) => item.id).toSet();
        _messages.insertAll(
          0,
          result.items.where((item) => !known.contains(item.id)),
        );
        _hasMore = result.hasMore;
        _nextBeforeId = result.nextBeforeMessageId;
        _loadingOlder = false;
      });
    } on ChatFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _loadingOlder = false;
        _error = failure.message;
      });
      if (failure.sessionEnded) _expireSession();
    }
  }

  void _selectConversation(ChatConversation conversation) {
    setState(() {
      _selected = conversation;
      _draftConnection = null;
      _messages.clear();
      _hasMore = false;
      _nextBeforeId = null;
      _loadingOlder = false;
      _showThread = true;
      _error = null;
    });
    _loadHistory(conversation);
  }

  void _selectConnection(ChatConnection connection) {
    setState(() {
      _selected = null;
      _draftConnection = connection;
      _messages.clear();
      _hasMore = false;
      _loadingOlder = false;
      _showThread = true;
      _error = null;
    });
  }

  Future<void> _startConversation() async {
    final token = _token;
    if (token == null) return;
    try {
      final connections = await _repository.acceptedConnections(token);
      if (!mounted) return;
      final existingIds = _conversations
          .map((item) => item.otherUserId)
          .toSet();
      final eligible = connections
          .where((item) => !existingIds.contains(item.userId))
          .toList(growable: false);
      final chosen = await showDialog<ChatConnection>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Start a conversation'),
          content: SizedBox(
            width: 420,
            child: eligible.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'You already have conversations with all your accepted connections.',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: eligible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final connection = eligible[index];
                      return ListTile(
                        leading: _Avatar(name: connection.fullName, size: 42),
                        title: Text(connection.fullName),
                        subtitle: const Text('Accepted connection'),
                        onTap: () => Navigator.pop(dialogContext, connection),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (chosen != null) _selectConnection(chosen);
    } on ChatFailure catch (failure) {
      _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    }
  }

  Future<void> _sendMessage() async {
    final connection = _draftConnection;
    final conversation = _selected;
    final recipientId = connection?.userId ?? conversation?.otherUserId;
    final text = _composer.text;
    final token = _token;
    if (recipientId == null || token == null || _sending) return;
    if (text.trim().isEmpty) return;
    if (text.length > 5000) {
      _showError('Messages can contain at most 5,000 characters.');
      return;
    }
    final messageId =
        _retryContent == text &&
            _retryRecipientId == recipientId &&
            _retryMessageId != null
        ? _retryMessageId!
        : _uuidV4();
    setState(() {
      _sending = true;
      _retryMessageId = messageId;
      _retryContent = text;
      _retryRecipientId = recipientId;
    });
    try {
      final sent = await _repository.send(
        token,
        receiverId: recipientId,
        clientMessageId: messageId,
        content: text,
      );
      if (!mounted) return;
      _composer.clear();
      setState(() {
        _retryMessageId = null;
        _retryContent = null;
        _retryRecipientId = null;
        _selected = ChatConversation(
          id: sent.conversationId,
          otherUserId: recipientId,
          otherFullName: connection?.fullName ?? conversation!.otherFullName,
          canSend: true,
          unreadCount: 0,
          lastMessageAt: sent.sentAt,
          latestVisibleMessage: sent,
        );
        _draftConnection = null;
        _messages.add(sent);
        _showThread = true;
      });
      await _refreshInbox(quiet: true);
      final current = _conversations.where(
        (item) => item.id == sent.conversationId,
      );
      if (current.isNotEmpty && mounted) {
        setState(() => _selected = current.first);
      }
      _scrollToLatest();
    } on ChatFailure catch (failure) {
      if (mounted) _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage message, bool forEveryone) async {
    final token = _token;
    if (token == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(forEveryone ? 'Delete for everyone?' : 'Delete for you?'),
        content: Text(
          forEveryone
              ? 'The message content will be removed from both participants’ histories.'
              : 'This message will be hidden from your own history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteMessage(
        token,
        message.id,
        forEveryone: forEveryone,
      );
      if (!forEveryone && mounted) {
        setState(() => _messages.removeWhere((item) => item.id == message.id));
      }
      final selected = _selected;
      if (selected != null) await _loadHistory(selected, quiet: true);
      await _refreshInbox(quiet: true);
    } on ChatFailure catch (failure) {
      _showError(failure.message);
      if (failure.sessionEnded) _expireSession();
    }
  }

  void _expireSession() {
    if (!mounted) return;
    _showError('Your session has ended. Returning to login.');
    widget.sessionController.expire();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messageList.hasClients) {
        _messageList.animateTo(
          _messageList.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _uuidV4() {
    // This UUID is an idempotency key, not a credential or security token.
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-${value.substring(12, 16)}-${value.substring(16, 20)}-${value.substring(20)}';
  }

  void _toggleTheme() {
    final preference = ThemePreference.maybeOf(context);
    if (preference == null) return;
    preference.value = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void _showUnavailable(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$section is not available in this build yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _navigationItem(
    String title,
    IconData icon, {
    required bool active,
    String? badge,
    bool soon = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final selectedColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF23412B)
        : const Color(0xFFF3E2E0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: active ? selectedColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: soon
              ? null
              : title == 'Messages'
              ? () => setState(() => _showThread = false)
              : () => _showUnavailable(title),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: active ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                if (soon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.outlineVariant),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  )
                else if (badge != null)
                  Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebar() {
    final colors = Theme.of(context).colorScheme;
    final account = widget.sessionController.account;
    final unreadCount = _conversations.fold<int>(
      0,
      (sum, item) => sum + item.unreadCount,
    );
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF03291C)
            : const Color(0xFFFFFAFA),
        border: Border(
          right: BorderSide(color: colors.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 20, 26),
            child: Row(
              children: [
                Image.asset('assets/auth/logo-light-transparent.png', width: 42),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(
                    text: 'Uni',
                    children: [
                      TextSpan(
                        text: 'Connect',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: .82),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.7,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _navLabel('Main'),
                _navigationItem('Home', Icons.home_outlined, active: false),
                _navigationItem('Discover', Icons.search, active: false),
                _navigationItem(
                  'Connections',
                  Icons.people_outline,
                  active: false,
                ),
                _navigationItem(
                  'Messages',
                  Icons.chat_bubble_outline,
                  active: true,
                  badge: unreadCount > 0 ? '$unreadCount' : null,
                ),
                _navigationItem(
                  'Notifications',
                  Icons.notifications_none,
                  active: false,
                  badge: '4',
                ),
                _navLabel('Campus'),
                _navigationItem(
                  'Clubs & events',
                  Icons.calendar_today_outlined,
                  active: false,
                ),
                _navigationItem(
                  'Project finder',
                  Icons.layers_outlined,
                  active: false,
                ),
                _navigationItem(
                  'Career board',
                  Icons.work_outline,
                  active: false,
                ),
                _navigationItem(
                  'Mentorship',
                  Icons.school_outlined,
                  active: false,
                  soon: true,
                ),
                _navLabel('Account'),
                _navigationItem(
                  'My profile',
                  Icons.person_outline,
                  active: false,
                ),
                _navigationItem(
                  'Administration',
                  Icons.shield_outlined,
                  active: false,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: .4)),
            ),
            child: Row(
              children: [
                _Avatar(name: account?.fullName ?? 'You', size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account?.fullName ?? 'Your account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        account?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Log out',
                  onPressed: widget.sessionController.logout,
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLabel(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 15, 16, 8),
    child: Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _topBar({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget actionButton({
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
      Widget? child,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(56, 56),
        backgroundColor: colors.surface.withValues(alpha: .7),
        foregroundColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: child ?? Icon(icon, size: 23),
    );

    return Container(
      height: 88,
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 30),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF022318) : const Color(0xFFF8F3F2),
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: .35)),
        ),
      ),
      child: Row(
        children: [
          if (compact)
            IconButton(
              tooltip: 'Back to inbox',
              onPressed: () => setState(() => _showThread = false),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search people, clubs, projects',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: .3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          if (!compact) const Spacer(),
          actionButton(
            tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
            onPressed: _toggleTheme,
          ),
          const SizedBox(width: 12),
          actionButton(
            tooltip: 'Notifications',
            icon: Icons.notifications_none,
            onPressed: () => _showUnavailable('Notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none, size: 23),
                Positioned(
                  right: -9,
                  top: -10,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '4',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            actionButton(
              tooltip: 'Profile',
              icon: Icons.person_outline,
              onPressed: () => _showUnavailable('Profile'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedName = _selected?.otherFullName ?? _draftConnection?.fullName;
    return ScaffoldMessenger(
      key: _pageKey,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1240;
              return Row(
                children: [
                  if (!compact) _sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        _topBar(compact: compact),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 8 : 42,
                              compact ? 10 : 42,
                              compact ? 8 : 42,
                              compact ? 10 : 20,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1440,
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(
                                      compact ? 18 : 30,
                                    ),
                                    border: Border.all(
                                      color: colors.outlineVariant.withValues(
                                        alpha: .48,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: .06,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      compact ? 18 : 30,
                                    ),
                                    child: SizedBox.expand(
                                      child: Row(
                                        children: [
                                          if (!compact || !_showThread)
                                            SizedBox(
                                              width: compact
                                                  ? double.infinity
                                                  : 450,
                                              child: _inboxPane(colors),
                                            ),
                                          if (!compact || _showThread)
                                            Expanded(
                                              child: _threadPane(
                                                colors,
                                                selectedName,
                                                compact: compact,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _inboxPane(ColorScheme colors) {
    final filtered = _conversations
        .where((item) {
          final query = _search.text.trim().toLowerCase();
          return query.isEmpty ||
              item.otherFullName.toLowerCase().contains(query);
        })
        .toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Messages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Start a conversation',
                onPressed: _startConversation,
                icon: const Icon(Icons.edit_square),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: .65)),
        Expanded(
          child: _loadingInbox && _conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? _EmptyInbox(onStart: _startConversation)
              : RefreshIndicator(
                  onRefresh: _refreshInbox,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final active = item.id == _selected?.id;
                      return _ConversationTile(
                        conversation: item,
                        selected: active,
                        onTap: () => _selectConversation(item),
                      );
                    },
                  ),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!, style: TextStyle(color: colors.error)),
          ),
      ],
    );
  }

  Widget _threadPane(
    ColorScheme colors,
    String? selectedName, {
    required bool compact,
  }) {
    if (selectedName == null) {
      return _WelcomePane(onStart: _startConversation);
    }
    final canSend = _selected?.canSend ?? true;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.outlineVariant.withValues(alpha: .65),
              ),
            ),
          ),
          child: Row(
            children: [
              if (compact)
                IconButton(
                  tooltip: 'Back to inbox',
                  onPressed: () => setState(() => _showThread = false),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              _Avatar(name: selectedName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      canSend ? 'Connected' : 'Chat history',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selected != null)
                IconButton(
                  tooltip: 'Reload conversation',
                  onPressed: () => _loadHistory(_selected!),
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loadingHistory && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
              ? _EmptyThread(name: selectedName)
              : ListView.builder(
                  controller: _messageList,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  itemCount: _messages.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_hasMore && index == 0) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: _loadingOlder ? null : _loadOlder,
                          icon: _loadingOlder
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.history_rounded),
                          label: const Text('Load older messages'),
                        ),
                      );
                    }
                    final message = _messages[index - (_hasMore ? 1 : 0)];
                    final own = message.senderId == _myUserId;
                    return _MessageBubble(
                      message: message,
                      own: own,
                      onDeleteSelf: () => _deleteMessage(message, false),
                      onDeleteEveryone: own
                          ? () => _deleteMessage(message, true)
                          : null,
                    );
                  },
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_error!, style: TextStyle(color: colors.error)),
            ),
          ),
        if (!canSend)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: colors.surfaceContainerHighest.withValues(alpha: .55),
            child: const Text(
              'This connection is no longer active. You can still read and manage your chat history.',
            ),
          )
        else
          _composerBar(colors),
      ],
    );
  }

  Widget _composerBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .65)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 5,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Write a message',
                counterText: '',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF042B1D)
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: .55),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: colors.primary),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 56,
            width: 72,
            child: FilledButton(
              onPressed: _sending || _composer.text.trim().isEmpty
                  ? null
                  : _sendMessage,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                padding: const EdgeInsets.all(14),
              ),
              child: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final ChatConversation conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF23412B)
        : const Color(0xFFF3E2E0);
    final latest = conversation.latestVisibleMessage;
    final subtitle =
        latest?.content ??
        (latest?.deletedForEveryone == true
            ? 'Message deleted'
            : 'No messages yet');
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? colors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              _Avatar(name: conversation.otherFullName, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherFullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (latest != null)
                          Text(
                            _shortTime(latest.sentAt),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.own,
    required this.onDeleteSelf,
    required this.onDeleteEveryone,
  });

  final ChatMessage message;
  final bool own;
  final VoidCallback onDeleteSelf;
  final VoidCallback? onDeleteEveryone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bubble = own ? colors.primary : colors.surfaceContainerHighest;
    final foreground = own ? colors.onPrimary : colors.onSurface;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .72,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PopupMenuButton<String>(
            tooltip: 'Message actions',
            onSelected: (value) {
              if (value == 'self') onDeleteSelf();
              if (value == 'everyone') onDeleteEveryone?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'self', child: Text('Delete for me')),
              if (onDeleteEveryone != null)
                const PopupMenuItem(
                  value: 'everyone',
                  child: Text('Delete for everyone'),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: message.deletedForEveryone
                    ? colors.surfaceContainerHighest
                    : bubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(own ? 18 : 5),
                  bottomRight: Radius.circular(own ? 5 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content ?? 'This message was deleted.',
                    style: TextStyle(
                      color: message.deletedForEveryone
                          ? colors.onSurfaceVariant
                          : foreground,
                      fontStyle: message.deletedForEveryone
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _clockTime(message.sentAt),
                        style: TextStyle(
                          color: foreground.withValues(alpha: .72),
                          fontSize: 10,
                        ),
                      ),
                      if (own && !message.deletedForEveryone) ...[
                        const SizedBox(width: 5),
                        Icon(
                          message.readAt != null
                              ? Icons.done_all_rounded
                              : message.deliveredAt != null
                              ? Icons.done_all_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: message.readAt != null
                              ? colors.tertiary
                              : foreground.withValues(alpha: .72),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final avatarColor = switch (initials.isEmpty ? '?' : initials[0]) {
      'N' => const Color(0xFFFF8F84),
      'T' => const Color(0xFF69D2BD),
      'M' => const Color(0xFFF6C85F),
      'R' => const Color(0xFF9AA8FF),
      _ => const Color(0xFF8EC9E8),
    };
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: avatarColor,
      foregroundColor: const Color(0xFF15212A),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(fontSize: size * .31, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 46,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('Your inbox is quiet'),
          const SizedBox(height: 4),
          Text(
            'Start a chat with one of your accepted connections.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.add),
            label: const Text('New message'),
          ),
        ],
      ),
    ),
  );
}

class _WelcomePane extends StatelessWidget {
  const _WelcomePane({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'Good conversations start here',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a conversation or message an accepted connection.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.edit_square),
            label: const Text('New message'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(name: name, size: 70),
          const SizedBox(height: 14),
          Text(
            'Say hello to $name',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Your first message will start this conversation.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

String _shortTime(DateTime time) {
  final now = DateTime.now();
  if (now.difference(time).inDays == 0 && now.day == time.day) {
    return _clockTime(time);
  }
  if (now.difference(time).inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }
  return '${time.month}/${time.day}';
}

String _clockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
}
