import 'dart:math';

import 'package:logging/logging.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timesheet/models/auth_info.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/services/auth_service.dart';

class AuthServiceImpl implements IAuthService {
  final _log = Logger("AuthService");
  final Uri _issuerUrl;
  final String _clientId;
  final String _scope;
  final int _authPort;
  Issuer? _issuer;
  Client? _client;
  Authenticator? _authenticator;

  AuthServiceImpl({
    required Uri issuerUrl,
    required String clientId,
    required Uri wtmBaseUrl,
  }) : _issuerUrl = issuerUrl,
       _clientId = clientId,
       _scope = 'openid ${wtmBaseUrl.toString()}',
       _authPort = 30000 + Random().nextInt(10001);

  @override
  Future<Result<AuthInfo>> authenticate() async {
    _log.fine('Authenticating...');

    try {
      if (_authenticator == null) {
        final initResult = await _initialize();
        if (initResult case Error()) {
          return Result.error(initResult.message);
        }
      }

      final credential = await _authenticator!.authorize();
      final tokenResponse = await credential.getTokenResponse();
      final userInfo = await credential.getUserInfo();

      _log.fine('Authentication finished.');

      return Result.ok(
        AuthInfo(
          accessToken: tokenResponse.accessToken ?? '',
          name: userInfo.name ?? 'Unknown User',
          email: userInfo.email,
          expiresAt: tokenResponse.expiresAt,
        ),
      );
    } catch (e, stackTrace) {
      _log.shout('Authentication error', e, stackTrace);
      return Result.error('Authentication failed: ${e.toString()}');
    }
  }

  Future<Result<void>> _initialize() async {
    _log.fine('Initializing OIDC client.');

    try {
      _issuer = await Issuer.discover(_issuerUrl);
      _client = Client(_issuer!, _clientId);

      _authenticator = Authenticator(
        _client!,
        scopes: [_scope],
        port: _authPort,
        urlLancher: (url) async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            _log.shout('Could not launch $url');
          }
        },
      );

      _log.fine('OIDC client initialized.');

      return Result.ok(null);
    } catch (e) {
      _log.shout('Failed to initialize OIDC client.', e);
      return Result.error('Failed to initialize OIDC client.');
    }
  }
}
