import 'package:flutter/material.dart';
import 'package:uniconnect/core/network/api_client.dart';
import 'package:uniconnect/features/authentication/controller/session_controller.dart';
import 'package:uniconnect/features/authentication/data/auth_transport.dart';
import 'package:uniconnect/features/authentication/data/session_repository.dart';

/// Owns credentials and the HTTP connection for the application's lifetime.
class SessionHost extends StatefulWidget {
  const SessionHost({required this.child, this.repository, super.key});
  final Widget child;
  final SessionRepository? repository;
  @override
  State<SessionHost> createState() => _SessionHostState();
}

class _SessionHostState extends State<SessionHost> {
  late final ApiClient _client = ApiClient();
  late final SessionController _controller = SessionController(
    widget.repository ?? ApiSessionRepository(AuthTransport(_client)),
  );
  @override
  void dispose() {
    _controller.dispose();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SessionScope(controller: _controller, child: widget.child);
}

class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    required SessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);
  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
  static SessionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
}
