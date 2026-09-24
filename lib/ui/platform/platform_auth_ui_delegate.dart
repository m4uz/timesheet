import 'package:timesheet/providers/auth_ui_delegate.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/snackbar.dart';

class PlatformAuthUiDelegate implements AuthUiDelegate {
  @override
  void showSessionExpiredDialog({
    required void Function(bool confirmed) onResult,
  }) {
    Dialog.warningConfirmation(
      title: 'Session Expired',
      message: 'Your session has expired. Please log in again.',
      confirmText: 'Log In',
      cancelText: 'Log Out',
      onResult: onResult,
    );
  }

  @override
  void notifyError(String message) {
    Snackbar.error(message);
  }
}
