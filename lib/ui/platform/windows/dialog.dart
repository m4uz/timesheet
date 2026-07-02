import 'package:fluent_ui/fluent_ui.dart';

class DialogManager {
  DialogManager._();
  static final DialogManager _instance = DialogManager._();
  static DialogManager get instance => _instance;

  GlobalKey<NavigatorState>? _navigatorKey;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance._navigatorKey = navigatorKey;
  }

  BuildContext? get _context => _navigatorKey?.currentContext;

  static void warningConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required void Function(bool confirmed) onResult,
  }) {
    _instance._warningConfirmation(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onResult: onResult,
    );
  }

  void _warningConfirmation({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required void Function(bool confirmed) onResult,
  }) {
    final context = _context;
    if (context == null) {
      onResult(false);
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Button(
            child: Text(cancelText),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          FilledButton(
            child: Text(confirmText),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ).then((value) => onResult(value ?? false));
  }

  static Future<T?> show<T>({
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) async {
    final context = _instance._context;
    if (context == null) return null;
    return showDialog<T>(
      context: context,
      builder: (ctx) =>
          ContentDialog(title: Text(title), content: content, actions: actions),
    );
  }
}
