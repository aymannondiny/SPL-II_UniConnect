part of '../chat_page.dart';

extension _ChatNavigation on _ChatPageState {
  void _expireSession() {
    if (!mounted) return;
    _showError('Your session has ended. Returning to login.');
    widget.sessionController.expire();
  }

  void _showError(String message) {
    if (!mounted) return;
    (_pageKey.currentState ?? ScaffoldMessenger.maybeOf(context))?.showSnackBar(
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

  void _openWorkspaceFeature(String feature) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.workspace,
      arguments: feature == 'Home' ? null : feature,
    );
  }
}
