import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

enum DialogSeverity { info, success, warning, error }

class DialogData {
  final DialogSeverity severity;
  final String title;
  final String message;
  final String primaryButtonText;
  final String? secondaryButtonText;
  final void Function(bool)? onResult;

  const DialogData({
    required this.severity,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    this.secondaryButtonText,
    this.onResult,
  });
}

class DialogManager {
  static final DialogManager _instance = DialogManager._internal();
  factory DialogManager() => _instance;
  DialogManager._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  final Queue<DialogData> _dialogQueue = Queue<DialogData>();
  bool _isShowing = false;

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
    _instance._enqueue(
      severity: DialogSeverity.warning,
      title: title,
      message: message,
      primaryButtonText: confirmText,
      secondaryButtonText: cancelText,
      onResult: onResult,
    );
  }

  void _enqueue({
    required DialogSeverity severity,
    required String title,
    required String message,
    required String primaryButtonText,
    String? secondaryButtonText,
    void Function(bool)? onResult,
  }) {
    _dialogQueue.add(
      DialogData(
        severity: severity,
        title: title,
        message: message,
        primaryButtonText: primaryButtonText,
        secondaryButtonText: secondaryButtonText,
        onResult: onResult,
      ),
    );
    _showNextDialog();
  }

  void _showNextDialog() {
    if (_isShowing || _dialogQueue.isEmpty) {
      return;
    }

    final context = _context;
    if (context == null) {
      final data = _dialogQueue.removeFirst();
      _handleDialogFailure(data: data);
      return;
    }

    final data = _dialogQueue.removeFirst();
    _isShowing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        _handleDialogFailure(data: data);
        return;
      }

      try {
        final result = await showMacosAlertDialog<bool>(
          context: context,
          builder: (ctx) => MacosAlertDialog(
            appIcon: MacosIcon(_getIcon(data.severity), size: 64),
            title: Text(data.title),
            message: Text(data.message),
            primaryButton: PushButton(
              controlSize: ControlSize.large,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(data.primaryButtonText),
            ),
            secondaryButton: data.secondaryButtonText != null
                ? PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(data.secondaryButtonText!),
                  )
                : null,
          ),
        );

        data.onResult?.call(result ?? false);
      } catch (e) {
        data.onResult?.call(false);
      } finally {
        _isShowing = false;
        _showNextDialog();
      }
    });
  }

  void _handleDialogFailure({required DialogData data}) {
    data.onResult?.call(false);
    _isShowing = false;
    _showNextDialog();
  }

  IconData _getIcon(DialogSeverity severity) {
    switch (severity) {
      case DialogSeverity.info:
        return CupertinoIcons.info_circle;
      case DialogSeverity.success:
        return CupertinoIcons.check_mark_circled;
      case DialogSeverity.warning:
        return CupertinoIcons.exclamationmark_triangle;
      case DialogSeverity.error:
        return CupertinoIcons.exclamationmark_circle;
    }
  }
}
