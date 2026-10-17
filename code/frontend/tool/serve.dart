import 'dart:io';

/// Loopback-only static server with SPA fallback for local release-build checks.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln('Usage: dart tool/serve.dart <build-directory> <port>');
    exitCode = 64;
    return;
  }
  final root = Directory(Directory(arguments[0]).resolveSymbolicLinksSync());
  if (!File.fromUri(root.uri.resolve('index.html')).existsSync()) {
    throw ArgumentError('Build directory must contain index.html.');
  }
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    int.parse(arguments[1]),
  );
  stdout.writeln('Serving ${root.path} at http://127.0.0.1:${server.port}');
  await for (final request in server) {
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
      } else {
        final relative = request.uri.path == '/'
            ? 'index.html'
            : request.uri.path.substring(1);
        var file = File.fromUri(root.uri.resolve(relative));
        final allowed = file.absolute.path.startsWith(
          '${root.path}${Platform.pathSeparator}',
        );
        if (!allowed) {
          request.response.statusCode = HttpStatus.forbidden;
        } else {
          if (!file.existsSync() &&
              !request.uri.path.split('/').last.contains('.')) {
            file = File.fromUri(root.uri.resolve('index.html'));
          }
          if (!file.existsSync()) {
            request.response.statusCode = HttpStatus.notFound;
          } else {
            request.response.headers.set('Cache-Control', 'no-store');
            request.response.headers.set(
              'Content-Type',
              _contentType(file.path),
            );
            if (request.method != 'HEAD') {
              await request.response.addStream(file.openRead());
            }
          }
        }
      }
      await request.response.close();
    } on Object catch (error) {
      stderr.writeln('Static response failed: ${error.runtimeType}');
      await request.response.close();
    }
  }
}

String _contentType(String path) => switch (path.split('.').last) {
  'html' => 'text/html; charset=utf-8',
  'js' => 'application/javascript',
  'json' => 'application/json',
  'wasm' => 'application/wasm',
  'css' => 'text/css',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'svg' => 'image/svg+xml',
  'woff' => 'font/woff',
  'woff2' => 'font/woff2',
  _ => 'application/octet-stream',
};
