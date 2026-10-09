import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Dialog;
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/macos/macos_layout.dart';
import 'package:timesheet/ui/platform/macos/toolbar_text_field.dart'
    as mac_toolbar_text_field;
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timetracker/macos/timetracker_item_row.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_summary_footer.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';

class TimetrackerView extends StatefulWidget {
  const TimetrackerView({super.key});

  @override
  State<TimetrackerView> createState() => _TimetrackerViewState();
}

class _TimetrackerViewState extends State<TimetrackerView> {
  final TextEditingController _filterController = TextEditingController();
  final _rowKeys = TimetrackerRowKeyMap<TimetrackerItemRowState>();

  Future<void> _onTabFromDescription({
    required TimetrackerProvider provider,
    required int index,
  }) {
    return handleTimetrackerTabFromDescription(
      provider: provider,
      index: index,
      isMounted: () => mounted,
      focusDateMonth: (itemId) {
        _rowKeys.forId(itemId).currentState?.focusDateMonth();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TimetrackerProvider, SubjectsAndCategoriesProvider>(
      builder: (context, timeTrackerProvider, userConfigProvider, child) {
        _showProviderMessages(timeTrackerProvider, userConfigProvider);

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

  void _showProviderMessages(
    TimetrackerProvider timeTrackerProvider,
    SubjectsAndCategoriesProvider userConfigProvider,
  ) {
    if (timeTrackerProvider.successMsg != null) {
      Snackbar.success(timeTrackerProvider.successMsg!);
      timeTrackerProvider.clearSuccessMsg();
    }
    if (timeTrackerProvider.errorMsg != null) {
      Snackbar.error(timeTrackerProvider.errorMsg!);
      timeTrackerProvider.clearErrorMsg();
    }
    if (userConfigProvider.errorMsg != null) {
      Snackbar.error(userConfigProvider.errorMsg!);
      userConfigProvider.clearErrorMsg();
    }
  }

  ToolBar _buildToolBar(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    return ToolBar(
      title: Text(
        'Timetracker',
        style: MacosTheme.of(context).typography.title2,
      ),
      titleWidth: MacosLayout.toolbarTitleWidthShort,
      leading: const MacosSidebarToggle(),
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
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    return ContentArea(
      builder: (context, scrollController) {
        if (userConfigProvider.isLoading) {
          return const Center(child: ProgressCircle());
        }
        return PinnedFooterLayout(
          footerHeight: TimetrackerSummaryFooter.reservedHeight,
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
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    _rowKeys.pruneTo(timeTrackerProvider.items.map((e) => e.id));

    return ReorderableListView(
      buildDefaultDragHandles: false,
      children: [
        for (int index = 0; index < timeTrackerProvider.items.length; index++)
          TimetrackerItemRow(
            key: _rowKeys.forId(timeTrackerProvider.items[index].id),
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
            index: index,
            item: timeTrackerProvider.items[index],
            canReorder: !timeTrackerProvider.hasFilter,
            onTabFromDescription: () => _onTabFromDescription(
              provider: timeTrackerProvider,
              index: index,
            ),
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

    return TimetrackerSummaryFooter(
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
