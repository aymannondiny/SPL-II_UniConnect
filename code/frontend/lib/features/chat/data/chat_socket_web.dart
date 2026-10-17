import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'chat_socket_contract.dart';

Future<ChatSocketConnection> connectChatSocket(Uri uri, String accessToken) {
  final socket = web.WebSocket(uri.toString());
  final connection = _WebChatSocket(socket);
  final ready = Completer<ChatSocketConnection>();
  socket.addEventListener(
    'open',
    ((web.Event _) {
      socket.send('AUTH $accessToken');
      if (!ready.isCompleted) ready.complete(connection);
    }).toJS,
  );
  socket.addEventListener(
    'error',
    ((web.Event _) {
      socket.close();
      if (!ready.isCompleted) {
        ready.completeError(StateError('Unable to connect to chat.'));
      }
    }).toJS,
  );
  return ready.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      socket.close();
      throw TimeoutException('Chat connection timed out.');
    },
  );
}

class _WebChatSocket implements ChatSocketConnection {
  _WebChatSocket(this._socket) {
    _socket.addEventListener(
      'message',
      ((web.Event event) {
        final data = (event as web.MessageEvent).data;
        if (data case final JSString message) _messages.add(message.toDart);
      }).toJS,
    );
    _socket.addEventListener(
      'close',
      ((web.Event _) {
        unawaited(_messages.close());
      }).toJS,
    );
    _socket.addEventListener(
      'error',
      ((web.Event error) => _messages.addError(error)).toJS,
    );
  }

  final web.WebSocket _socket;
  final StreamController<String> _messages = StreamController<String>();

  @override
  Stream<String> get messages => _messages.stream;

  @override
  void send(String message) => _socket.send(message);

  @override
  Future<void> close() async {
    _socket.close();
    await _messages.close();
  }
}
