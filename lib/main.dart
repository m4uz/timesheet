import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/config/app_config.dart';
import 'package:timesheet/config/http_client_config.dart';
import 'package:timesheet/config/log_config.dart';
import 'package:timesheet/factories/service_factory.dart';
import 'package:timesheet/platform_menu.dart';
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
import 'package:timesheet/theme.dart';
import 'package:timesheet/ui/dialog.dart';
import 'package:timesheet/ui/snackbar.dart';
import 'package:timesheet/ui/views/config_view.dart';
import 'package:timesheet/ui/views/debug_view.dart';
import 'package:timesheet/ui/views/login_view.dart';
import 'package:timesheet/ui/views/timetracker_view.dart';
import 'package:timesheet/ui/views/timesheet_view.dart';
import 'package:timesheet/ui/views/subjects_categories_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
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
  late final SessionManager sessionManager = SessionManager();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    DialogManager.initialize(navigatorKey);
    SnackBarManager.initialize(navigatorKey);
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
        Provider<IAuthService>(
          create: (_) => ServiceFactory.createAuthService(),
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
          create: (context) =>
              HttpClient(sessionManager: context.read<SessionManager>()),
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
        final authProvider = context.watch<AuthProvider>();

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
          home: authProvider.isAuthenticated
              ? const Timesheet()
              : const LoginView(),
        );
      },
    );
  }
}

class Timesheet extends StatefulWidget {
  const Timesheet({super.key});

  @override
  State<Timesheet> createState() => _TimesheetState();
}

class _TimesheetState extends State<Timesheet> {
  int pageIndex = 0;

  late final searchFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: menuBarItems(),
      child: MacosWindow(
        sidebar: Sidebar(
          minWidth: 200,
          builder: (context, scrollController) {
            return SidebarItems(
              currentIndex: pageIndex,
              onChanged: (i) {
                setState(() => pageIndex = i);
              },
              scrollController: scrollController,
              itemSize: SidebarItemSize.large,
              items: const [
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.stopwatch),
                  label: Text('Timetracker'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.calendar),
                  label: Text('Timesheet'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.list_bullet),
                  label: Text('Subjects & Categories'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.settings),
                  label: Text('Config'),
                ),
                if (!kReleaseMode)
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.ant),
                    label: Text('Debug'),
                  ),
              ],
            );
          },
          bottom: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MacosListTile(
                leading: const MacosIcon(CupertinoIcons.profile_circled),
                title: Text(authProvider.userName ?? 'User'),
                subtitle: Text(authProvider.userEmail ?? ''),
              );
            },
          ),
        ),
        child: [
          const TimetrackerView(),
          const TimeSheetView(),
          const SubjectsCategoriesView(),
          const ConfigView(),
          if (!kReleaseMode) const DebugView(),
        ][pageIndex],
      ),
    );
  }
}
