import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/platform/macos/menu_bar.dart' as mac_menu_bar;
import 'package:timesheet/ui/views/config/macos/config_view.dart' as mac_config_view;
import 'package:timesheet/ui/views/debug/macos/debug_view.dart' as mac_debug_view;
import 'package:timesheet/ui/views/menu/destinations.dart';
import 'package:timesheet/ui/views/subjects_categories/macos/subjects_categories_view.dart'
    as mac_subjects_categories_view;
import 'package:timesheet/ui/views/timesheet/macos/timesheet_view.dart' as mac_timesheet_view;
import 'package:timesheet/ui/views/timetracker/macos/timetracker_view.dart' as mac_timetracker_view;

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = visibleMenuDestinations(releaseMode: kReleaseMode);
    final selectedIndex = _selectedIndex.clamp(0, destinations.length - 1);

    return PlatformMenuBar(
      menus: mac_menu_bar.menuBarItems(),
      child: MacosWindow(
        sidebar: Sidebar(
          minWidth: 200,
          builder: (context, scrollController) {
            return SidebarItems(
              currentIndex: selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
              scrollController: scrollController,
              itemSize: SidebarItemSize.large,
              items: [
                for (final destination in destinations)
                  SidebarItem(
                    leading: MacosIcon(_iconFor(destination.id)),
                    label: Text(destination.label),
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
          for (final destination in destinations) _viewFor(destination.id),
        ][selectedIndex],
      ),
    );
  }

  IconData _iconFor(MenuDestination destination) {
    return switch (destination) {
      MenuDestination.timetracker => CupertinoIcons.stopwatch,
      MenuDestination.timesheet => CupertinoIcons.calendar,
      MenuDestination.subjectsCategories => CupertinoIcons.list_bullet,
      MenuDestination.config => CupertinoIcons.settings,
      MenuDestination.debug => CupertinoIcons.ant,
    };
  }

  Widget _viewFor(MenuDestination destination) {
    return switch (destination) {
      MenuDestination.timetracker => const mac_timetracker_view.TimetrackerView(),
      MenuDestination.timesheet => const mac_timesheet_view.TimesheetView(),
      MenuDestination.subjectsCategories =>
        const mac_subjects_categories_view.SubjectsCategoriesView(),
      MenuDestination.config => const mac_config_view.ConfigView(),
      MenuDestination.debug => const mac_debug_view.DebugView(),
    };
  }
}
