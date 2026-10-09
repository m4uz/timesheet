import 'package:flutter/material.dart' hide Dialog;
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:yaru/yaru.dart';

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
    return Scaffold(
      appBar: const YaruWindowTitleBar(
        border: BorderSide.none,
        title: Text('Debug'),
      ),
      body: SingleChildScrollView(
        padding: LinuxLayout.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: LinuxLayout.space12,
              runSpacing: LinuxLayout.space8,
              children: [
                FilledButton(
                  onPressed: () => Snackbar.info('This is an info message'),
                  child: const Text('Info SnackBar'),
                ),
                FilledButton(
                  onPressed: () =>
                      Snackbar.success('This is a success message'),
                  child: const Text('Success SnackBar'),
                ),
                FilledButton(
                  onPressed: () =>
                      Snackbar.warning('This is a warning message'),
                  child: const Text('Warning SnackBar'),
                ),
                FilledButton(
                  onPressed: () => Snackbar.error('This is an error message'),
                  child: const Text('Error SnackBar'),
                ),
              ],
            ),
            const SizedBox(height: LinuxLayout.space16),
            FilledButton(
              onPressed: () {
                Dialog.warningConfirmation(
                  title: 'Confirm',
                  message: 'Confirm dialog?',
                  confirmText: 'Yes',
                  cancelText: 'Cancel',
                  onResult: (confirmed) {
                    if (confirmed) {
                      Snackbar.success('Dialog option confirmed');
                    } else {
                      Snackbar.info('Dialog option dismissed');
                    }
                    setState(() {});
                  },
                );
              },
              child: const Text('Show dialog'),
            ),
            const SizedBox(height: LinuxLayout.space20 * 1.6),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                _syncToken(auth.accessToken);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Token refresh',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: LinuxLayout.space12),
                    FilledButton(
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
                    const SizedBox(height: LinuxLayout.space12),
                    SizedBox(
                      width: 600,
                      child: TextField(
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
