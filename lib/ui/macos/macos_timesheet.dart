import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/ui/platform_menu.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/macos/views/config_view.dart';
import 'package:timesheet/ui/macos/views/debug_view.dart';
import 'package:timesheet/ui/macos/views/timetracker_view.dart';
import 'package:timesheet/ui/macos/views/timesheet_view.dart';
import 'package:timesheet/ui/macos/views/subjects_categories_view.dart';

class MacosTimesheet extends StatefulWidget {
  const MacosTimesheet({super.key});

  @override
  State<MacosTimesheet> createState() => _MacosTimesheetState();
}

class _MacosTimesheetState extends State<MacosTimesheet> {
  int pageIndex = 0;

  late final searchFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: menuBarItems(),
      child: MacosWindow(
        sidebar: Sidebar(
          minWidth: 200,
          builder: (context, scrollController) {
            return SidebarItems(
              currentIndex: pageIndex,
              onChanged: (i) {
                setState(() => pageIndex = i);
              },
              scrollController: scrollController,
              itemSize: SidebarItemSize.large,
              items: const [
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.stopwatch),
                  label: Text('Timetracker'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.calendar),
                  label: Text('Timesheet'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.list_bullet),
                  label: Text('Subjects & Categories'),
                ),
                SidebarItem(
                  leading: MacosIcon(CupertinoIcons.settings),
                  label: Text('Config'),
                ),
                if (!kReleaseMode)
                  SidebarItem(
                    leading: MacosIcon(CupertinoIcons.ant),
                    label: Text('Debug'),
                  ),
              ],
            );
          },
          bottom: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return MacosListTile(
                leading: const MacosIcon(CupertinoIcons.profile_circled),
                title: Text(authProvider.userName ?? 'User'),
                subtitle: Text(authProvider.userEmail ?? ''),
              );
            },
          ),
        ),
        child: [
          const TimetrackerView(),
          const TimeSheetView(),
          const SubjectsCategoriesView(),
          const ConfigView(),
          if (!kReleaseMode) const DebugView(),
        ][pageIndex],
      ),
    );
  }
}
