import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column.dart';

Future<void> showTimesheetColumnMenu(
  BuildContext context,
  Offset globalPosition,
) async {
  final controller = FlyoutController();
  final overlay = Overlay.of(context);
  final navigator = Navigator.of(context);
  final navigatorBox = navigator.context.findRenderObject()! as RenderBox;
  final position = navigatorBox.globalToLocal(globalPosition);
  final attachKey = GlobalKey();

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: globalPosition.dx,
      top: globalPosition.dy,
      width: 1,
      height: 1,
      child: FlyoutTarget(
        key: attachKey,
        controller: controller,
        child: const SizedBox.shrink(),
      ),
    ),
  );

  overlay.insert(entry);
  await WidgetsBinding.instance.endOfFrame;

  if (!context.mounted) {
    entry.remove();
    controller.dispose();
    return;
  }

  await controller.showFlyout<void>(
    navigatorKey: navigator,
    barrierColor: Colors.black.withValues(alpha: 0.1),
    position: position,
    barrierRecognizer: TapGestureRecognizer(),
    builder: (context) {
      return Consumer<TimesheetProvider>(
        builder: (context, provider, _) {
          return MenuFlyout(
            items: [
              for (final column in TimesheetColumn.values)
                ToggleMenuFlyoutItem(
                  text: Text(column.label),
                  value: provider.isColumnVisible(column),
                  closeAfterClick: false,
                  onChanged: (_) => provider.toggleColumn(column),
                ),
            ],
          );
        },
      );
    },
  );

  entry.remove();
  controller.dispose();
}
