import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

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

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: YaruDialogTitleBar(title: Text(title)),
        content: Text(message),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    ).then((value) => onResult(value ?? false));
  }
}
