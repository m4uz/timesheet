import 'dart:async';
import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

enum SnackBarSeverity { info, success, warning, error }

class SnackBarManager {
  static final SnackBarManager _instance = SnackBarManager._internal();
  factory SnackBarManager() => _instance;
  SnackBarManager._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  final Queue<({SnackBarSeverity severity, String message})> _snackBarQueue =
      Queue<({SnackBarSeverity severity, String message})>();
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _instance._navigatorKey = navigatorKey;
  }

  BuildContext? get _context => _navigatorKey?.currentContext;

  OverlayState? get _overlay => _navigatorKey?.currentState?.overlay;

  static void info(String message) {
    _instance._enqueue(severity: SnackBarSeverity.info, message: message);
  }

  static void success(String message) {
    _instance._enqueue(severity: SnackBarSeverity.success, message: message);
  }

  static void warning(String message) {
    _instance._enqueue(severity: SnackBarSeverity.warning, message: message);
  }

  static void error(String message) {
    _instance._enqueue(severity: SnackBarSeverity.error, message: message);
  }

  void _enqueue({required SnackBarSeverity severity, required String message}) {
    _snackBarQueue.add((severity: severity, message: message));
    _showNextSnackBar();
  }

  void _showNextSnackBar() {
    if (_overlayEntry != null || _snackBarQueue.isEmpty) {
      return;
    }

    final context = _context;
    if (context == null) {
      // If no context available, remove from queue and try next
      _snackBarQueue.removeFirst();
      return;
    }

    final data = _snackBarQueue.removeFirst();

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _SnackBar(
        severity: data.severity,
        message: data.message,
        onDismiss: () => _hideSnackBar(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = _overlay;
      if (_overlayEntry != null && overlay != null) {
        overlay.insert(_overlayEntry!);

        _dismissTimer = Timer(const Duration(seconds: 10), () {
          _hideSnackBar();
        });
      } else {
        // Overlay became unavailable, clean up
        _overlayEntry = null;
      }
    });
  }

  void _hideSnackBar() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    _overlayEntry?.remove();
    _overlayEntry = null;

    _showNextSnackBar();
  }
}

class _SnackBar extends StatelessWidget {
  final SnackBarSeverity severity;
  final String message;
  final VoidCallback onDismiss;

  const _SnackBar({
    required this.severity,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          children: [
            MacosIcon(_getIcon(), color: colors.outline),
            SizedBox(width: 16),
            Expanded(
              child: SelectableText(
                message,
                style: MacosTheme.of(context).typography.body,
              ),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: MacosIcon(CupertinoIcons.clear, color: colors.outline),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (severity) {
      case SnackBarSeverity.info:
        return CupertinoIcons.info_circle;
      case SnackBarSeverity.success:
        return CupertinoIcons.check_mark_circled;
      case SnackBarSeverity.warning:
        return CupertinoIcons.exclamationmark_triangle;
      case SnackBarSeverity.error:
        return CupertinoIcons.exclamationmark_circle;
    }
  }

  ({Color background, Color outline}) _getColors() {
    switch (severity) {
      case SnackBarSeverity.info:
        return (background: Colors.blue.shade50, outline: Colors.blue);
      case SnackBarSeverity.success:
        return (background: Colors.green.shade50, outline: Colors.green);
      case SnackBarSeverity.warning:
        return (background: Colors.orange.shade50, outline: Colors.orange);
      case SnackBarSeverity.error:
        return (background: Colors.red.shade50, outline: Colors.red);
    }
  }
}
