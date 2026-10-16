import 'package:web/web.dart' as web;

/// Read once in main, then remove the reset token from the current history entry.
void clearResetFragment() {
  web.window.history.replaceState(null, '', '/reset-password');
}
