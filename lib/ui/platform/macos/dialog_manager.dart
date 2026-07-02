import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

class DialogManager {
  DialogManager._();
  static final DialogManager _instance = DialogManager._();

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

    showMacosAlertDialog<bool>(
      context: context,
      builder: (ctx) => MacosAlertDialog(
        appIcon: const MacosIcon(
          CupertinoIcons.exclamationmark_triangle,
          size: 64,
        ),
        title: Text(title),
        message: Text(message),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText),
        ),
        secondaryButton: PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText),
        ),
      ),
    ).then((value) => onResult(value ?? false));
  }
}
