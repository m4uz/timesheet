import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/views/config/windows/config_view.dart';
import 'package:timesheet/ui/views/debug/windows/debug_view.dart';
import 'package:timesheet/ui/views/menu/destinations.dart';
import 'package:timesheet/ui/views/subjects_categories/windows/subjects_categories_view.dart';
import 'package:timesheet/ui/views/timesheet/windows/timesheet_view.dart';
import 'package:timesheet/ui/views/timetracker/windows/timetracker_view.dart';

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

    return NavigationView(
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
        items: [
          for (final destination in destinations)
            PaneItem(
              icon: WindowsIcon(_iconFor(destination.id)),
              title: Text(destination.label),
              body: _viewFor(destination.id),
            ),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: const WindowsIcon(WindowsIcons.contact),
            title: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Text(authProvider.userName ?? 'User');
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MenuDestination destination) {
    return switch (destination) {
      MenuDestination.timetracker => WindowsIcons.stopwatch,
      MenuDestination.timesheet => WindowsIcons.calendar,
      MenuDestination.subjectsCategories => WindowsIcons.bulleted_list,
      MenuDestination.config => WindowsIcons.settings,
      MenuDestination.debug => WindowsIcons.bug,
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
