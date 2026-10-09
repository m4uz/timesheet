import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column.dart';
import 'package:yaru/yaru.dart';

Future<void> showTimesheetColumnMenu(
  BuildContext context,
  Offset globalPosition,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _TimesheetColumnMenu(
        position: globalPosition,
        animation: animation,
      );
    },
  );
}

class _TimesheetColumnMenu extends StatelessWidget {
  const _TimesheetColumnMenu({
    required this.position,
    required this.animation,
  });

  final Offset position;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: FadeTransition(
            opacity: animation,
            child: Consumer<TimesheetProvider>(
              builder: (context, provider, _) {
                return Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(LinuxLayout.fieldRadius),
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: LinuxLayout.menuPadding,
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final column in TimesheetColumn.values)
                            _MenuItem(
                              label: column.label,
                              checked: provider.isColumnVisible(column),
                              onTap: () => provider.toggleColumn(column),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = theme.colorScheme.primary;
    final textColor = _hovered
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: LinuxLayout.menuItemHeight,
          padding: const EdgeInsets.symmetric(horizontal: LinuxLayout.space6),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: _hovered ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(LinuxLayout.menuItemRadius),
          ),
          child: Row(
            children: [
              SizedBox(
                width: LinuxLayout.menuCheckSlotWidth,
                child: widget.checked
                    ? Icon(
                        YaruIcons.checkmark,
                        size: LinuxLayout.menuCheckIconSize,
                        color: textColor,
                      )
                    : null,
              ),
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
