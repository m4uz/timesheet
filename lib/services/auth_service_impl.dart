import 'package:logging/logging.dart';
import 'package:openid_client/openid_client.dart';
import 'package:timesheet/models/auth_info.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/services/auth_service.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:timesheet/services/oidc_flow_helper.dart';

class AuthServiceImpl implements IAuthService {
  final _log = Logger('AuthService');
  final OidcAuthCoordinator _coordinator;
  final OidcFlowHelper _flowHelper;

  AuthServiceImpl({
    required OidcAuthCoordinator coordinator,
    required Uri issuerUrl,
    required String clientId,
    required Uri wtmBaseUrl,
  }) : _coordinator = coordinator,
       _flowHelper = OidcFlowHelper(
         issuerUrl: issuerUrl,
         clientId: clientId,
         wtmBaseUrl: wtmBaseUrl,
       );

  @override
  Future<Result<AuthInfo>> authenticate() {
    return _authorize(interactive: true);
  }

  @override
  Future<Result<AuthInfo>> refreshSession() {
    return _authorize(interactive: false);
  }

  Future<Result<AuthInfo>> _authorize({required bool interactive}) async {
    _log.fine(interactive ? 'Authenticating...' : 'Refreshing session...');

    try {
      final flow = await _flowHelper.createFlow(interactive: interactive);
      final queryParameters = await _coordinator.authorize(
        flow.authenticationUri,
        interactive: interactive,
      );
      final credential = await _flowHelper.completeAuthorization(
        flow,
        queryParameters,
      );
      final authInfo = await _flowHelper.toAuthInfo(credential);

      _log.fine(interactive ? 'Authentication finished.' : 'Session refreshed.');

      return Result.ok(authInfo);
    } on OpenIdException catch (e, stackTrace) {
      _log.shout(
        interactive ? 'Authentication error' : 'Session refresh error',
        e,
        stackTrace,
      );
      return Result.error(e.message ?? 'Authentication failed.');
    } catch (e, stackTrace) {
      _log.shout(
        interactive ? 'Authentication error' : 'Session refresh error',
        e,
        stackTrace,
      );
      return Result.error('Authentication failed: ${e.toString()}');
    }
  }
}
