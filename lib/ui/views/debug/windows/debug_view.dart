import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/platform/windows/dialog.dart';
import 'package:timesheet/ui/platform/windows/infobar.dart';

class DebugView extends StatefulWidget {
  const DebugView({super.key});

  @override
  State<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView> {
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _syncToken(String? token) {
    final value = token ?? '';
    if (_tokenController.text != value) {
      _tokenController.text = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Debug')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Button(
                  onPressed: () =>
                      InfoBarManager.info('This is an info message'),
                  child: const Text('Info SnackBar'),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () =>
                      InfoBarManager.success('This is a success message'),
                  child: const Text('Success SnackBar'),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () =>
                      InfoBarManager.warning('This is a warning message'),
                  child: const Text('Warning SnackBar'),
                ),
                const SizedBox(width: 12),
                Button(
                  onPressed: () =>
                      InfoBarManager.error('This is an error message'),
                  child: const Text('Error SnackBar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Button(
                  child: const Text('Show dialog'),
                  onPressed: () {
                    DialogManager.warningConfirmation(
                      title: 'Confirm',
                      message: 'Confirm dialog?',
                      confirmText: 'Yes',
                      cancelText: 'Cancel',
                      onResult: (confirmed) {
                        if (confirmed) {
                          InfoBarManager.success('Dialog option confirmed');
                        } else {
                          InfoBarManager.info('Dialog option dismissed');
                        }
                        setState(() {});
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                _syncToken(auth.accessToken);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token refresh',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 12),
                    Button(
                      onPressed: auth.isRefreshing
                          ? null
                          : () async {
                              await context.read<AuthProvider>().refreshToken(
                                showErrors: true,
                              );
                            },
                      child: Text(
                        auth.isRefreshing ? 'Refreshing...' : 'Refresh token',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 600,
                      child: TextBox(
                        controller: _tokenController,
                        readOnly: true,
                        maxLines: 4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
