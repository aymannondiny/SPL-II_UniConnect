import 'chat_socket_contract.dart';
import 'chat_socket_stub.dart'
    if (dart.library.io) 'chat_socket_io.dart'
    if (dart.library.js_interop) 'chat_socket_web.dart'
    as platform;

export 'chat_socket_contract.dart';

Future<ChatSocketConnection> connectChatSocket(Uri uri, String accessToken) =>
    platform.connectChatSocket(uri, accessToken);
