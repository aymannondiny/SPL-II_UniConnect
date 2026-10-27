import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/appearance_menu_button.dart';
import 'package:uniconnect/core/config/app_config.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/core/routing/app_router.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_dimensions.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/chat/data/chat_repository.dart';
import 'package:uniconnect/features/chat/data/chat_socket_contract.dart';
import 'package:uniconnect/features/chat/model/chat_models.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_mobile_navigation.dart';
import 'package:uniconnect/features/home/view/widgets/workspace_sidebar.dart';

import 'widgets/chat_conversation_tile.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_ribbon_background.dart';
import 'widgets/chat_avatar.dart';
import 'widgets/chat_empty_inbox.dart';
import 'widgets/chat_welcome_pane.dart';
import 'widgets/chat_empty_thread.dart';

part 'parts/chat_realtime.dart';
part 'parts/chat_inbox.dart';
part 'parts/chat_recipients.dart';
part 'parts/chat_mutations.dart';
part 'parts/chat_navigation.dart';
part 'parts/chat_chrome.dart';
part 'parts/chat_layout.dart';
part 'parts/chat_thread.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.sessionController,
    this.repository,
    this.embedded = false,
    this.active = true,
    this.initialRecipient,
    this.openRequestId = 0,
    this.recipientRequest = 0,
    super.key,
  });

  final SessionController sessionController;
  final ChatRepository? repository;
  final bool embedded;
  final bool active;
  final ChatConnection? initialRecipient;
  final int openRequestId;
  final int recipientRequest;

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
  final Set<String> _sendingMessageIds = {};
  final Map<String, _PendingSendTarget> _pendingSendTargets = {};
  final Map<int, List<ChatMessage>> _localOutbox = {};
  int _nextPendingMessageId = -1;
  bool _hasMore = false;
  int? _nextBeforeId;
  String? _error;
  final Set<int> _historyRequestsInFlight = {};
  final Set<int> _pendingHistoryRefreshes = {};
  int _handledOpenRequestId = 0;
  Timer? _pollTimer;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  StreamSubscription<String>? _socketSubscription;
  ChatSocketConnection? _socket;
  String? _socketToken;
  int _reconnectCount = 0;
  bool _showThread = false;
  bool _inboxLoaded = false;
  ChatConnection? _pendingRecipient;
  int _recipientGeneration = 0;

  String? get _token => widget.sessionController.currentAccessToken;
  int? get _myUserId => widget.sessionController.account?.userId;
  int get _recipientRequestId => widget.openRequestId != 0
      ? widget.openRequestId
      : widget.recipientRequest;

  @override
  void initState() {
    super.initState();
    _client = ApiClient();
    _repository = widget.repository ?? ChatRepository(_client);
    widget.sessionController.addListener(_sessionChanged);
    _pendingRecipient = widget.initialRecipient;
    _refreshInbox();
    _connectSocket();
    if (widget.active) _startPolling();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldRecipientRequestId = oldWidget.openRequestId != 0
        ? oldWidget.openRequestId
        : oldWidget.recipientRequest;
    final openingRequestedRecipient =
        _recipientRequestId != oldRecipientRequestId;
    final becomingActive = !oldWidget.active && widget.active;
    if (openingRequestedRecipient && !becomingActive) {
      _openRequestedRecipient();
    }
    if (becomingActive) {
      _refreshInbox(quiet: true);
      final selected = _selected;
      if (!openingRequestedRecipient && selected != null && _showThread) {
        _loadHistory(selected, quiet: true, rerunIfInFlight: true);
      }
      _startPolling();
    } else if (oldWidget.active && !widget.active) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
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

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _update(VoidCallback change) => setState(change);

  void _upsertVisibleMessage(ChatMessage message) {
    final index = _messages.indexWhere(
      (item) =>
          item.id == message.id ||
          (message.clientMessageId.isNotEmpty &&
              item.clientMessageId == message.clientMessageId),
    );
    if (index >= 0) {
      _messages[index] = message;
    } else {
      _messages.add(message);
    }
    _messages.sort((left, right) {
      final byTime = left.sentAt.compareTo(right.sentAt);
      return byTime != 0 ? byTime : left.id.compareTo(right.id);
    });
  }

  void _mergeAuthoritativeMessages(Iterable<ChatMessage> messages) {
    for (final message in messages) {
      _removeLocalMessage(message.clientMessageId);
      _upsertVisibleMessage(message);
    }
  }

  void _removeLocalMessage(String clientMessageId) {
    if (clientMessageId.isEmpty) return;
    for (final messages in _localOutbox.values) {
      messages.removeWhere(
        (message) => message.clientMessageId == clientMessageId,
      );
    }
    _localOutbox.removeWhere((_, messages) => messages.isEmpty);
    _pendingSendTargets.remove(clientMessageId);
    _sendingMessageIds.remove(clientMessageId);
  }

  void _replaceLocalMessage(ChatMessage message) {
    final target = _pendingSendTargets[message.clientMessageId];
    if (target == null) return;
    final outbox = _localOutbox[target.recipientId];
    if (outbox != null) {
      final index = outbox.indexWhere(
        (item) => item.clientMessageId == message.clientMessageId,
      );
      if (index >= 0) outbox[index] = message;
    }
    if (_selected?.otherUserId == target.recipientId ||
        _draftConnection?.userId == target.recipientId) {
      _upsertVisibleMessage(message);
    }
  }

  void _restoreLocalMessages(int recipientId) {
    for (final message in _localOutbox[recipientId] ?? const <ChatMessage>[]) {
      _upsertVisibleMessage(message);
    }
  }

  void _logSendTiming(
    String clientMessageId,
    String milestone,
    Stopwatch stopwatch,
  ) {
    if (!AppConfig.chatPerformanceLogging) return;
    debugPrint(
      'chat_send correlation=$clientMessageId milestone=$milestone '
      'elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
  }

  void _sessionChanged() {
    final token = _token;
    if (token == null) {
      if (mounted && !widget.embedded) Navigator.of(context).pop();
      return;
    }
    if (token != _socketToken) _connectSocket();
  }

  void _openRequestedRecipient() {
    final requestId = _recipientRequestId;
    final recipient = widget.initialRecipient;
    if (requestId == 0 ||
        requestId == _handledOpenRequestId ||
        recipient == null ||
        !_inboxLoaded) {
      return;
    }
    _handledOpenRequestId = requestId;
    final existing = _conversations.where(
      (conversation) => conversation.otherUserId == recipient.userId,
    );
    if (existing.isNotEmpty) {
      _selectConversation(existing.first);
    } else {
      _selectConnection(recipient);
    }
  }
}

class _PendingSendTarget {
  const _PendingSendTarget({required this.recipientId, required this.fullName});

  final int recipientId;
  final String fullName;
}
