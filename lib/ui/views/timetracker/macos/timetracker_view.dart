import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Dialog;
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/macos/toolbar_text_field.dart'
    as mac_toolbar_text_field;
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timetracker/macos/timetracker_item_row.dart';
import 'package:timesheet/ui/widgets/duration_footer.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';

class TimetrackerView extends StatefulWidget {
  const TimetrackerView({super.key});

  @override
  State<TimetrackerView> createState() => _TimetrackerViewState();
}

class _TimetrackerViewState extends State<TimetrackerView> {
  final TextEditingController _filterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetrackerProvider, SubjectsCategoriesProvider>(
      builder: (context, timeTrackerProvider, userConfigProvider, child) {
        _showProviderMessages(timeTrackerProvider);

        return MacosScaffold(
          toolBar: _buildToolBar(
            context,
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
          ),
          children: [
            _buildContentArea(
              context,
              timeTrackerProvider: timeTrackerProvider,
              userConfigProvider: userConfigProvider,
            ),
          ],
        );
      },
    );
  }

  void _showProviderMessages(TimetrackerProvider provider) {
    if (provider.successMsg != null) {
      Snackbar.success(provider.successMsg!);
      provider.clearSuccessMsg();
    }
    if (provider.errorMsg != null) {
      Snackbar.error(provider.errorMsg!);
      provider.clearErrorMsg();
    }
  }

  ToolBar _buildToolBar(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return ToolBar(
      title: Text(
        'Timetracker',
        style: MacosTheme.of(context).typography.title2,
      ),
      titleWidth: 100.0,
      leading: MacosTooltip(
        message: 'Toggle Sidebar',
        useMousePosition: false,
        child: MacosIconButton(
          icon: MacosIcon(
            CupertinoIcons.sidebar_left,
            color: MacosTheme.brightnessOf(context).resolve(
              const Color.fromRGBO(0, 0, 0, 0.5),
              const Color.fromRGBO(255, 255, 255, 0.5),
            ),
            size: 20.0,
          ),
          boxConstraints: const BoxConstraints(
            minHeight: 20,
            minWidth: 20,
            maxWidth: 48,
            maxHeight: 38,
          ),
          onPressed: () => MacosWindowScope.of(context).toggleSidebar(),
        ),
      ),
      actions: [
        ToolBarIconButton(
          label: 'Add item',
          showLabel: false,
          icon: const MacosIcon(CupertinoIcons.plus_circle),
          tooltipMessage: 'Add timesheet item',
          onPressed: () async {
            timeTrackerProvider.addItem();
          },
        ),
        mac_toolbar_text_field.ToolbarTextField(
          controller: _filterController,
          placeholder: 'Filter',
          onChanged: timeTrackerProvider.setFilter,
        ),
        ToolBarIconButton(
          label: 'Save to WTM',
          showLabel: false,
          icon: const MacosIcon(CupertinoIcons.cloud_upload),
          tooltipMessage: 'Save timesheet items to WTM',
          onPressed: () async {
            await timeTrackerProvider.saveToWTM();
            await userConfigProvider.loadSubjectsAndCategories();
          },
        ),
        ToolBarIconButton(
          label: 'Clear timesheet',
          showLabel: false,
          icon: const MacosIcon(CupertinoIcons.trash),
          tooltipMessage: 'Clear all timesheet items',
          onPressed: () async {
            Dialog.warningConfirmation(
              title: 'Warning',
              message: 'Are you sure you want to delete all items?',
              confirmText: 'Yes',
              cancelText: 'No',
              onResult: (confirmed) {
                if (confirmed) {
                  timeTrackerProvider.deleteAll();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return ContentArea(
      builder: (context, scrollController) {
        return PinnedFooterLayout(
          footerHeight: DurationFooter.reservedHeight,
          body: _buildItemList(
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
          ),
          footer: _buildFooter(context, timeTrackerProvider),
        );
      },
    );
  }

  Widget _buildItemList({
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      children: [
        for (int index = 0; index < timeTrackerProvider.items.length; index++)
          TimetrackerItemRow(
            key: ValueKey(timeTrackerProvider.items[index].itemIndex),
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
            index: index,
            item: timeTrackerProvider.items[index],
            canReorder: !timeTrackerProvider.hasFilter,
          ),
      ],
      onReorderItem: (oldIndex, newIndex) async {
        if (timeTrackerProvider.hasFilter) {
          return;
        }
        await timeTrackerProvider.reorderItems(oldIndex, newIndex);
      },
    );
  }

  Widget _buildFooter(BuildContext context, TimetrackerProvider provider) {
    final theme = MacosTheme.of(context);

    return DurationFooter(
      durationByDate: provider.durationByDate,
      formatDate: (date) => DateFormat('d.M.').format(date),
      textStyle: theme.typography.body,
      emphasisTextStyle: theme.typography.headline,
      dividerColor: theme.dividerColor,
    );
  }

  @override
  void initState() {
    super.initState();
    _filterController.text = context.read<TimetrackerProvider>().filter;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}
