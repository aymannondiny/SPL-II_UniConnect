part of '../chat_page.dart';

extension _ChatRealtime on _ChatPageState {
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      final socketConnected = _token != null && _socketToken == _token;
      if (!socketConnected) {
        _refreshInbox(quiet: true);
        final selected = _selected;
        if (selected != null && _showThread) {
          _loadHistory(selected, quiet: true);
        }
      }
    });
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
            if (widget.active && type == 'READY') {
              _refreshInbox(quiet: true);
            } else if (widget.active && type == 'CHAT_CHANGED') {
              _refreshInbox(quiet: true);
              final selected = _selected;
              if (selected != null && _showThread) {
                _loadHistory(selected, quiet: true, rerunIfInFlight: true);
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
}
