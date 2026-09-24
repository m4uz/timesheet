import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_column.dart';

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
    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: FadeTransition(
            opacity: animation,
            child: Consumer<TimesheetProvider>(
              builder: (context, provider, _) {
                final pulldownTheme = MacosPulldownButtonTheme.of(context);

                return MacosOverlayFilter(
                  color: pulldownTheme.pulldownColor?.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
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
    final brightness = MacosTheme.brightnessOf(context);
    final highlightColor = MacosPulldownButtonTheme.of(context).highlightColor;
    final textColor = _hovered
        ? MacosColors.white
        : brightness.resolve(MacosColors.black, MacosColors.white);

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: _hovered ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                child: widget.checked
                    ? MacosIcon(
                        CupertinoIcons.checkmark_alt,
                        size: 16,
                        color: textColor,
                      )
                    : null,
              ),
              Text(
                widget.label,
                style: TextStyle(fontSize: 13, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
