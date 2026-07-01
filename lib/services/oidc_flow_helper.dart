import 'package:openid_client/openid_client.dart';
import 'package:timesheet/config/oidc_config.dart';
import 'package:timesheet/models/auth_info.dart';

class OidcFlowHelper {
  final Uri _issuerUrl;
  final String _clientId;
  final Uri _wtmBaseUrl;

  Issuer? _issuer;
  Client? _client;

  OidcFlowHelper({
    required Uri issuerUrl,
    required String clientId,
    required Uri wtmBaseUrl,
  }) : _issuerUrl = issuerUrl,
       _clientId = clientId,
       _wtmBaseUrl = wtmBaseUrl;

  Future<Client> getClient() async {
    _issuer ??= await Issuer.discover(_issuerUrl);
    _client ??= Client(_issuer!, _clientId);
    return _client!;
  }

  Future<Flow> createFlow({required bool interactive}) async {
    final client = await getClient();
    return Flow.authorizationCodeWithPKCE(
      client,
      prompt: interactive ? null : 'none',
      scopes: OidcConfig.scopes(_wtmBaseUrl),
    )..redirectUri = OidcConfig.redirectUri;
  }

  Future<Credential> completeAuthorization(
    Flow flow,
    Map<String, String> queryParameters,
  ) async {
    final error = queryParameters['error'];
    if (error != null) {
      throw OpenIdException(
        error,
        queryParameters['error_description'],
        queryParameters['error_uri'],
      );
    }

    return flow.callback(queryParameters);
  }

  static bool isInteractionRequired(OpenIdException exception) {
    final code = exception.code;
    if (code == null) {
      return false;
    }

    return RegExp(
      r'(interaction|login|account_selection|consent)_required',
      caseSensitive: false,
    ).hasMatch(code);
  }

  Future<AuthInfo> toAuthInfo(Credential credential) async {
    final tokenResponse = await credential.getTokenResponse();
    final userInfo = await credential.getUserInfo();

    return AuthInfo(
      accessToken: tokenResponse.accessToken ?? '',
      expiresAt: tokenResponse.expiresAt,
      name: userInfo.name ?? 'Unknown User',
      email: userInfo.email,
    );
  }
}
