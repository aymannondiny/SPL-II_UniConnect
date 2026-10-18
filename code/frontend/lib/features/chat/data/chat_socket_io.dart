import 'dart:async';
import 'dart:io';

import 'chat_socket_contract.dart';

Future<ChatSocketConnection> connectChatSocket(
  Uri uri,
  String accessToken,
) async {
  final socket = await WebSocket.connect(uri.toString())
      .timeout(const Duration(seconds: 10));
  socket.add('AUTH $accessToken');
  return _IoChatSocket(socket);
}

class _IoChatSocket implements ChatSocketConnection {
  _IoChatSocket(this._socket);
  final WebSocket _socket;

  @override
  Stream<String> get messages =>
      _socket.where((event) => event is String).cast<String>();

  @override
  void send(String message) => _socket.add(message);

  @override
  Future<void> close() async {
    await _socket.close();
  }
}
