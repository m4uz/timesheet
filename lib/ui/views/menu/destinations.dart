enum MenuDestination {
  timetracker,
  timesheet,
  subjectsCategories,
  config,
  debug,
}

class MenuDestinationDefinition {
  final MenuDestination id;
  final String label;
  final bool showInRelease;

  const MenuDestinationDefinition({
    required this.id,
    required this.label,
    this.showInRelease = true,
  });
}

const menuDestinations = <MenuDestinationDefinition>[
  MenuDestinationDefinition(
    id: MenuDestination.timetracker,
    label: 'Timetracker',
  ),
  MenuDestinationDefinition(id: MenuDestination.timesheet, label: 'Timesheet'),
  MenuDestinationDefinition(
    id: MenuDestination.subjectsCategories,
    label: 'Subjects & Categories',
  ),
  MenuDestinationDefinition(id: MenuDestination.config, label: 'Config'),
  MenuDestinationDefinition(
    id: MenuDestination.debug,
    label: 'Debug',
    showInRelease: false,
  ),
];

List<MenuDestinationDefinition> visibleMenuDestinations({
  required bool releaseMode,
}) {
  return menuDestinations
      .where((destination) => releaseMode ? destination.showInRelease : true)
      .toList(growable: false);
}
