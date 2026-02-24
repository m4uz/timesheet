import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:timesheet/ui/windows/views/config_view.dart';
import 'package:timesheet/ui/windows/views/debug_view.dart';
import 'package:timesheet/ui/windows/views/subjects_categories_view.dart';
import 'package:timesheet/ui/windows/views/timetracker_view.dart';
import 'package:timesheet/ui/windows/views/timesheet_view.dart';

class WindowsTimesheet extends StatefulWidget {
  const WindowsTimesheet({super.key});

  @override
  State<WindowsTimesheet> createState() => _WindowsTimesheetState();
}

class _WindowsTimesheetState extends State<WindowsTimesheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: [
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.stopwatch),
            title: const Text('Timetracker'),
            body: const TimetrackerView(),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.calendar),
            title: const Text('Timesheet'),
            body: const TimesheetView(),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.bulleted_list),
            title: const Text('Subjects & Categories'),
            body: const SubjectsCategoriesView(),
          ),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.settings),
            title: const Text('Config'),
            body: const ConfigView(),
          ),
          if (!kReleaseMode)
            PaneItem(
              icon: const WindowsIcon(WindowsIcons.bug),
              title: const Text('Debug'),
              body: const DebugView(),
            ),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.contact),
            title: const Text('Maurice Moss'),
          ),
        ],
      ),
    );
  }
}

class _MockView extends StatelessWidget {
  const _MockView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text(title)),
      content: Center(
        child: Text(
          '$title — mock view',
          style: FluentTheme.of(context).typography.body,
        ),
      ),
    );
  }
}
