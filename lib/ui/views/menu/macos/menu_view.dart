import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/platform/macos/menu_bar.dart';
import 'package:timesheet/ui/views/config/macos/config_view.dart';
import 'package:timesheet/ui/views/debug/macos/debug_view.dart';
import 'package:timesheet/ui/views/menu/destinations.dart';
import 'package:timesheet/ui/views/subjects_categories/macos/subjects_categories_view.dart';
import 'package:timesheet/ui/views/timesheet/macos/timesheet_view.dart';
import 'package:timesheet/ui/views/timetracker/macos/timetracker_view.dart';

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
      menus: menuBarItems(),
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
      MenuDestination.timetracker => const TimetrackerView(),
      MenuDestination.timesheet => const TimesheetView(),
      MenuDestination.subjectsCategories => const SubjectsCategoriesView(),
      MenuDestination.config => const ConfigView(),
      MenuDestination.debug => const DebugView(),
    };
  }
}
