import 'package:fluent_ui/fluent_ui.dart';

class InfoBarManager {
  InfoBarManager._();
  static final InfoBarManager _instance = InfoBarManager._();
  static InfoBarManager get instance => _instance;

  GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance._navigatorKey = navigatorKey;
  }

  OverlayState? get _overlay => _navigatorKey?.currentState?.overlay;

  static void info(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.info);
  }

  static void success(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.success);
  }

  static void warning(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.warning);
  }

  static void error(String message) {
    _instance._show(message: message, severity: InfoBarSeverity.error);
  }

  void _show({required String message, required InfoBarSeverity severity}) {
    final overlay = _overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: InfoBar(
            title: const Text(''),
            content: Text(message),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: () {
                entry.remove();
              },
            ),
            severity: severity,
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}
