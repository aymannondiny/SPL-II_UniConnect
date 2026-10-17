import 'dart:async';

abstract interface class ChatSocketConnection {
  Stream<String> get messages;
  void send(String message);
  Future<void> close();
}
