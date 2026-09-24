import 'package:flutter/widgets.dart'
    show
        PlatformMenu,
        PlatformMenuItem,
        PlatformProvidedMenuItem,
        PlatformProvidedMenuItemType;

List<PlatformMenuItem> menuBarItems() {
  return const [
    PlatformMenu(
      label: 'Timesheet',
      menus: [
        PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
        PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
      ],
    ),
  ];
}
