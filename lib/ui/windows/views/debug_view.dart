import 'package:fluent_ui/fluent_ui.dart';
import 'package:timesheet/ui/windows/dialog.dart';
import 'package:timesheet/ui/windows/infobar.dart';

class DebugView extends StatefulWidget {
  const DebugView({super.key});

  @override
  State<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends State<DebugView> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Debug')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Button(
                onPressed: () => InfoBarManager.info('This is an info message'),
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
                    message: 'Confirm dialog?',
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
        ],
      ),
    );
  }
}
