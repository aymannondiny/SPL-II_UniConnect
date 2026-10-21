import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uniconnect/core/config/app_config.dart';

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = Uri.parse(baseUrl ?? AppConfig.apiBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return _client.get(
      _resolve(path),
      headers: <String, String>{'Accept': 'application/json', ...?headers},
    );
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.post(
      _resolve(path),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.patch(
      _resolve(path),
      headers: <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...?headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return _client.delete(
      _resolve(path),
      headers: <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ...?headers,
      },
      body: body == null ? null : jsonEncode(body),
    );
  }

  Uri _resolve(String path) {
    String normalizedPath = path.startsWith('/') ? path : '/$path';
    return _baseUri.resolve(normalizedPath);
  }

  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) => _client.put(
    _resolve(path),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    },
    body: jsonEncode(body),
  );

  void close() {
    _client.close();
  }
}
