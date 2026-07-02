import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/macos/dialog.dart';
import 'package:timesheet/ui/macos/snackbar.dart';

class DebugView extends StatelessWidget {
  const DebugView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: Text(
          'Debug',
          style: MacosTheme.of(context).typography.title2,
        ),
        titleWidth: 150.0,
        leading: null,
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          SnackBarManager.info('This is an info message');
                        },
                        child: const Text('Info SnackBar'),
                      ),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          SnackBarManager.success('This is a success message');
                        },
                        child: const Text('Success SnackBar'),
                      ),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          SnackBarManager.warning('This is a warning message');
                        },
                        child: const Text('Warning SnackBar'),
                      ),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          SnackBarManager.error('This is an error message');
                        },
                        child: const Text('Error SnackBar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          DialogManager.warningConfirmation(
                            title: 'Warning Dialog',
                            message: 'Confirm warning?',
                            confirmText: 'Yes',
                            cancelText: 'No',
                            onResult: (bool confirmed) {},
                          );
                        },
                        child: const Text('Info Dialog'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const _TokenRefreshSection(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TokenRefreshSection extends StatefulWidget {
  const _TokenRefreshSection();

  @override
  State<_TokenRefreshSection> createState() => _TokenRefreshSectionState();
}

class _TokenRefreshSectionState extends State<_TokenRefreshSection> {
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        _syncToken(auth.accessToken);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Token refresh',
              style: MacosTheme.of(context).typography.title3,
            ),
            const SizedBox(height: 12),
            PushButton(
              controlSize: ControlSize.large,
              onPressed: auth.isRefreshing
                  ? null
                  : () async {
                      await context.read<AuthProvider>().refreshToken(
                        showErrors: true,
                      );
                    },
              child: Text(auth.isRefreshing ? 'Refreshing...' : 'Refresh token'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 600,
              child: MacosTextField(
                controller: _tokenController,
                readOnly: true,
                maxLines: 4,
              ),
            ),
          ],
        );
      },
    );
  }
}
