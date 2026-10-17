import 'package:web/web.dart' as web;

/// Keep the one-time token out of browser history after capturing it in memory.
void clearVerificationFragment() {
  web.window.history.replaceState(null, '', '/verify-email');
}
