import 'package:timesheet/config/app_config.dart';
import 'package:timesheet/http/http_client.dart';
import 'package:timesheet/services/auth_service.dart';
import 'package:timesheet/services/auth_service_impl.dart';
import 'package:timesheet/services/timetracker_db_service.dart';
import 'package:timesheet/services/timetracker_db_service_impl.dart';
import 'package:timesheet/services/wtm_service.dart';
import 'package:timesheet/services/wtm_service_impl.dart';

class ServiceFactory {
  static IAuthService createAuthService() {
    return AuthServiceImpl(
      issuerUrl: AppConfig.oidcIssuerUrl,
      clientId: AppConfig.oidcClientId,
      wtmBaseUrl: AppConfig.wtmBaseUrl,
    );
  }

  static IWTMService createWTMService({required HttpClient httpClient}) {
    return WTMServiceImpl(client: httpClient, wtmBaseUrl: AppConfig.wtmBaseUrl);
  }

  static TimetrackerDBService createTimetrackerDBService() {
    return TimetrackerDBServiceImpl(AppConfig.timetrackerDB);
  }
}
