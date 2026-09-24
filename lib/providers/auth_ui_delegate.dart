abstract class AuthUiDelegate {
  void showSessionExpiredDialog({
    required void Function(bool confirmed) onResult,
  });

  void notifyError(String message);
}
