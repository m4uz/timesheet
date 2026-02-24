import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:timesheet/ui/macos/snackbar.dart';
import 'package:timesheet/ui/macos/dialog.dart';

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
            return Column(
              children: [
                Row(
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        SnackBarManager.info("This is an info message");
                      },
                      child: const Text('Info SnackBar'),
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        SnackBarManager.success("This is a success message");
                      },
                      child: const Text('Success SnackBar'),
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        SnackBarManager.warning("This is a warning message");
                      },
                      child: const Text('Warning SnackBar'),
                    ),
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        SnackBarManager.error("This is an error message");
                      },
                      child: const Text('Error SnackBar'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        DialogManager.warningConfirmation(
                          title: "Warning Dialog",
                          message: "Confirm warning?",
                          confirmText: "Yes",
                          cancelText: "No",
                          onResult: (bool confirmed) {},
                        );
                      },
                      child: const Text('Info Dialog'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
