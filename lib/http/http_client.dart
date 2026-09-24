import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/http.dart' show Response;
import 'package:logging/logging.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:timesheet/services/session_manager.dart';

enum HttpMethod { get, post }

typedef SessionRefreshCallback = Future<bool> Function();

class HttpClient {
  final SessionManager _sessionManager;
  final SessionRefreshCallback? _refreshToken;
  final Logger _logger = Logger('HttpClient');
  final Duration _timeout = const Duration(minutes: 1);

  HttpClient({
    required this._sessionManager,
    this._refreshToken,
  });

  Future<Response?> get<T>(Uri uri, {Object? body}) async {
    return _executeRequest<T>(httpMethod: HttpMethod.get, uri: uri, body: body);
  }

  Future<Response?> post<T>(Uri uri, {Object? body}) async {
    return _executeRequest<T>(
      httpMethod: HttpMethod.post,
      uri: uri,
      body: body,
    );
  }

  Future<Response?> _executeRequest<T>({
    required HttpMethod httpMethod,
    required Uri uri,
    required Object? body,
  }) async {
    try {
      if (!await _ensureValidSession()) {
        if (_sessionManager.isEmpty) {
          _logger.severe('Operation stopped due to empty session.');
          return Response('Not authenticated.', 403);
        }
        _logger.warning('Operation stopped due to expired session.');
        return Response('Session expired.', 401);
      }

      var response = await _sendRequest(
        httpMethod: httpMethod,
        uri: uri,
        body: body,
      );

      if (response.statusCode == 401) {
        final refreshToken = _refreshToken;
        if (refreshToken != null) {
          _logger.fine('Received 401, attempting token refresh.');
          final refreshed = await refreshToken();
          if (refreshed) {
            response = await _sendRequest(
              httpMethod: httpMethod,
              uri: uri,
              body: body,
            );
          }
        }
      }

      return response;
    } on TimeoutException catch (e, stackTrace) {
      _logger.severe('Request timeout.', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error.', e, stackTrace);
      return null;
    }
  }

  Future<bool> _ensureValidSession() async {
    if (_sessionManager.isEmpty) {
      return false;
    }

    final session = _sessionManager.value;
    final needsRefresh =
        !session.isValid ||
        session.expiresWithin(OidcConfig.tokenRefreshLeeway);

    if (!needsRefresh) {
      return true;
    }

    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return session.isValid;
    }

    _logger.fine('Session expired or near expiry, refreshing token.');
    return await refreshToken();
  }

  Future<Response> _sendRequest({
    required HttpMethod httpMethod,
    required Uri uri,
    required Object? body,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    headers['Authorization'] = 'Bearer ${_sessionManager.accessToken}';

    final requestBody = body != null ? jsonEncode(body) : null;
    late final http.Response response;

    switch (httpMethod) {
      case HttpMethod.get:
        if (requestBody != null) {
          final client = http.Client();
          try {
            final request = http.Request('GET', uri)
              ..headers.addAll(headers)
              ..body = requestBody;
            response = await http.Response.fromStream(
              await client.send(request),
            ).timeout(_timeout);
          } finally {
            client.close();
          }
        } else {
          response = await http.get(uri, headers: headers).timeout(_timeout);
        }
      case HttpMethod.post:
        response = await http
            .post(uri, headers: headers, body: requestBody)
            .timeout(_timeout);
    }

    _logger.fine(
      '${httpMethod.name.toUpperCase()} ${uri.toString()} ${response.statusCode}',
    );

    return response;
  }
}
