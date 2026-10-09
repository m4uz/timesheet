import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/auth_provider.dart';
import 'package:timesheet/ui/views/config/linux/config_view.dart' as linux_config_view;
import 'package:timesheet/ui/views/debug/linux/debug_view.dart' as linux_debug_view;
import 'package:timesheet/ui/views/menu/destinations.dart';
import 'package:timesheet/ui/views/subjects_and_categories/linux/subjects_and_categories_view.dart'
    as linux_subjects_and_categories_view;
import 'package:timesheet/ui/views/timesheet/linux/timesheet_view.dart'
    as linux_timesheet_view;
import 'package:timesheet/ui/views/timetracker/linux/timetracker_view.dart'
    as linux_timetracker_view;
import 'package:yaru/yaru.dart';

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

    return YaruMasterDetailPage(
      length: destinations.length,
      initialIndex: _selectedIndex,
      onSelected: (index) {
        if (index != null) {
          setState(() => _selectedIndex = index);
        }
      },
      appBar: const YaruWindowTitleBar(
        title: Text('Timesheet'),
        border: BorderSide.none,
      ),
      tileBuilder: (context, index, selected, availableWidth) {
        final destination = destinations[index];
        return YaruMasterTile(
          leading: Icon(_iconFor(destination.id)),
          title: Text(destination.label),
        );
      },
      pageBuilder: (context, index) {
        final destination = destinations[index];
        return YaruDetailPage(
          body: _viewFor(destination.id),
        );
      },
      bottomBar: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return YaruMasterTile(
            leading: const Icon(YaruIcons.user),
            title: Text(authProvider.userName ?? 'User'),
          );
        },
      ),
    );
  }

  IconData _iconFor(MenuDestination destination) {
    return switch (destination) {
      MenuDestination.timetracker => YaruIcons.stopwatch,
      MenuDestination.timesheet => YaruIcons.calendar,
      MenuDestination.subjectsAndCategories => YaruIcons.unordered_list,
      MenuDestination.config => YaruIcons.settings,
      MenuDestination.debug => Icons.bug_report,
    };
  }

  Widget _viewFor(MenuDestination destination) {
    return switch (destination) {
      MenuDestination.timetracker =>
        const linux_timetracker_view.TimetrackerView(),
      MenuDestination.timesheet => const linux_timesheet_view.TimesheetView(),
      MenuDestination.subjectsAndCategories =>
        const linux_subjects_and_categories_view.SubjectsAndCategoriesView(),
      MenuDestination.config => const linux_config_view.ConfigView(),
      MenuDestination.debug => const linux_debug_view.DebugView(),
    };
  }
}
