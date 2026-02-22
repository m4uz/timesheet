import 'package:timesheet/models/auth_info.dart';
import 'package:timesheet/models/result.dart';

abstract class IAuthService {
  Future<Result<AuthInfo>> authenticate();
}
