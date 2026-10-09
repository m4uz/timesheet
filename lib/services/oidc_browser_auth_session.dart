import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:url_launcher/url_launcher.dart';

/// OIDC authorization via the system browser and a localhost redirect listener.
///
/// Used on Linux where embedding WebKitGTK in Flutter breaks the GL surface.
class OidcBrowserAuthSession {
  final _log = Logger('OidcBrowserAuthSession');

  HttpServer? _server;
  Completer<Map<String, String>>? _pendingAuthorization;
  bool _disposed = false;

  bool get isAuthorizing =>
      _pendingAuthorization != null && !_pendingAuthorization!.isCompleted;

  Future<Map<String, String>> authorize(Uri authorizationUri) async {
    _ensureNotDisposed();

    if (isAuthorizing) {
      throw StateError('Authorization already in progress.');
    }

    final completer = Completer<Map<String, String>>();
    _pendingAuthorization = completer;

    try {
      await _ensureServerListening();
      _log.fine('Opening system browser for authorization.');
      final launched = await launchUrl(
        authorizationUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('Could not open the system browser.');
      }

      return await completer.future.timeout(
        OidcConfig.authorizationTimeout,
        onTimeout: () {
          throw TimeoutException('Authorization timed out.');
        },
      );
    } finally {
      _pendingAuthorization = null;
      await _stopServer();
    }
  }

  void cancelAuthorization() {
    final pending = _pendingAuthorization;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(Exception('Authorization cancelled.'));
    }
    _pendingAuthorization = null;
    unawaited(_stopServer());
  }

  void dispose() {
    _disposed = true;
    cancelAuthorization();
  }

  Future<void> _ensureServerListening() async {
    if (_server != null) {
      return;
    }

    final redirect = OidcConfig.redirectUri;
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      redirect.port,
    );
    _log.fine('Listening for OIDC redirect on ${redirect.origin}${redirect.path}');

    _server!.listen((request) async {
      try {
        if (request.uri.path != redirect.path) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        final params = Map<String, String>.from(request.uri.queryParameters);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(
            '<!DOCTYPE html><html><body><h1>Login complete</h1>'
            '<p>You can close this window and return to Timesheet.</p>'
            '<script>window.close();</script></body></html>',
          );
        await request.response.close();

        final pending = _pendingAuthorization;
        if (pending != null && !pending.isCompleted) {
          pending.complete(params);
        }
      } catch (error, stackTrace) {
        _log.warning('OIDC redirect handler failed', error, stackTrace);
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  Future<void> _stopServer() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('OidcBrowserAuthSession has been disposed.');
    }
  }
}
