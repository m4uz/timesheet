import 'package:timesheet/models/auth_info.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/services/auth_service.dart';

class AuthRepository {
  final IAuthService _authService;

  AuthRepository({required IAuthService authService})
    : _authService = authService;

  Future<Result<AuthInfo>> authenticate() async {
    return await _authService.authenticate();
  }
}
