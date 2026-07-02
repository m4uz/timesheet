import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/config/app_config.dart';
import 'package:timesheet/config/http_client_config.dart';
import 'package:timesheet/config/log_config.dart';
import 'package:timesheet/factories/service_factory.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/providers/config_provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/models/session.dart';
import 'package:timesheet/repositories/auth_repository.dart';
import 'package:timesheet/repositories/config_repository.dart';
import 'package:timesheet/repositories/timesheet_repository.dart';
import 'package:timesheet/repositories/timetracker_repository.dart';
import 'package:timesheet/repositories/subjects_and_categories_repository.dart';
import 'package:timesheet/http/http_client.dart';
import 'package:timesheet/services/auth_service.dart';
import 'package:timesheet/services/session_manager.dart';
import 'package:timesheet/services/timetracker_db_service.dart';
import 'package:timesheet/services/wtm_service.dart';
import 'package:timesheet/ui/views/login/macos/login_view.dart' as mac_login_view;
import 'package:timesheet/ui/views/login/windows/login_view.dart'
    as win_login_view;
import 'package:timesheet/ui/views/menu/macos/menu_view.dart' as mac_menu_view;
import 'package:timesheet/ui/views/menu/windows/menu_view.dart' as win_menu_view;
import 'package:timesheet/ui/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/services/oidc_auth_coordinator.dart';
import 'package:timesheet/ui/platform/macos/oidc_auth_host.dart' as mac_oidc_auth_host;
import 'package:timesheet/ui/platform/windows/oidc_auth_host.dart' as win_oidc_auth_host;
import 'package:webview_all/webview_all.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Dialog.initialize(navigatorKey);
  Snackbar.initialize(navigatorKey);

  if (Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
    await MacosWindowUtilsConfig().apply();
  }

  await AppConfig.init();
  LogConfig.init(AppConfig.logFile, AppConfig.logLevel);
  HttpClientConfig.init(AppConfig.proxyHost, AppConfig.proxyPort);
  await initializeDateFormatting();

  runApp(const TimesheetApp());
}

class TimesheetApp extends StatefulWidget {
  const TimesheetApp({super.key});

  @override
  State<TimesheetApp> createState() => _TimesheetAppState();
}

class _TimesheetAppState extends State<TimesheetApp> {
  final SessionManager sessionManager = SessionManager();
  final OidcAuthCoordinator oidcAuthCoordinator = OidcAuthCoordinator();

  @override
  void dispose() {
    oidcAuthCoordinator.dispose();
    sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // **************************************************
        // Setup
        // **************************************************
        ValueListenableProvider<Session>.value(value: sessionManager),
        ListenableProvider<SessionManager>.value(value: sessionManager),
        ChangeNotifierProvider<OidcAuthCoordinator>.value(
          value: oidcAuthCoordinator,
        ),
        Provider<IAuthService>(
          create: (_) => ServiceFactory.createAuthService(
            coordinator: oidcAuthCoordinator,
          ),
        ),
        Provider<AuthRepository>(
          create: (context) =>
              AuthRepository(authService: context.read<IAuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
            sessionManager: context.read<SessionManager>(),
          ),
        ),
        Provider<HttpClient>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            return HttpClient(
              sessionManager: context.read<SessionManager>(),
              refreshToken: authProvider.refreshTokenForHttp,
            );
          },
        ),
        Provider<IWTMService>(
          create: (context) => ServiceFactory.createWTMService(
            httpClient: context.read<HttpClient>(),
          ),
        ),
        Provider<ConfigRepository>(create: (_) => ConfigRepository()),
        ChangeNotifierProvider(
          create: (context) =>
              ConfigProvider(repository: context.read<ConfigRepository>()),
        ),
        ChangeNotifierProvider(create: (_) => AppTheme()),

        // **************************************************
        // Timetracker
        // **************************************************
        Provider<TimetrackerDBService>(
          create: (_) => ServiceFactory.createTimetrackerDBService(),
        ),
        Provider<TimetrackerRepository>(
          create: (context) => TimetrackerRepository(
            dbService: context.read<TimetrackerDBService>(),
            wtmService: context.read<IWTMService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TimetrackerProvider(
            repository: context.read<TimetrackerRepository>(),
          ),
        ),

        // **************************************************
        // Timesheet
        // **************************************************
        Provider<TimesheetRepository>(
          create: (context) =>
              TimesheetRepository(service: context.read<IWTMService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TimesheetProvider(
            repository: context.read<TimesheetRepository>(),
          ),
        ),

        // **************************************************
        // Subjects & Categories
        // **************************************************
        Provider<SubjectsAndCategoriesRepository>(
          create: (context) => SubjectsAndCategoriesRepository(
            service: context.read<IWTMService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SubjectsCategoriesProvider(
            repository: context.read<SubjectsAndCategoriesRepository>(),
          ),
        ),
      ],
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();

        if (Platform.isWindows) {
          return FluentApp(
            navigatorKey: navigatorKey,
            title: '🦄⏰💩',
            themeMode: appTheme.mode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              FluentLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            debugShowCheckedModeBanner: !kReleaseMode,
            builder: (context, child) {
              return win_oidc_auth_host.WindowsOidcAuthHost(child: child);
            },
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isAuthenticated
                    ? const win_menu_view.MenuView()
                    : const win_login_view.LoginView();
              },
            ),
          );
        }

        return MacosApp(
          navigatorKey: navigatorKey,
          title: '🦄⏰💩',
          themeMode: appTheme.mode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          debugShowCheckedModeBanner: !kReleaseMode,
          builder: (context, child) {
            return mac_oidc_auth_host.MacosOidcAuthHost(child: child);
          },
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return auth.isAuthenticated
                  ? const mac_menu_view.MenuView()
                  : const mac_login_view.LoginView();
            },
          ),
        );
      },
    );
  }
}
