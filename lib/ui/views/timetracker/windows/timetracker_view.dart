import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/subjects_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timetracker/windows/timetracker_item_row.dart';
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
      builder: (context, timeTrackerProvider, userConfigProvider, _) {
        _showProviderMessages(timeTrackerProvider);

        return ScaffoldPage(
          header: _buildPageHeader(
            context,
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
          ),
          content: _buildContentArea(
            context,
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
          ),
        );
      },
    );
  }

  void _showProviderMessages(TimetrackerProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.successMsg != null) {
        Snackbar.success(provider.successMsg!);
        provider.clearSuccessMsg();
      }
      if (provider.errorMsg != null) {
        Snackbar.error(provider.errorMsg!);
        provider.clearErrorMsg();
      }
    });
  }

  PageHeader _buildPageHeader(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return PageHeader(
      title: const Text('Timetracker'),
      commandBar: _buildCommandBar(
        timeTrackerProvider: timeTrackerProvider,
        userConfigProvider: userConfigProvider,
      ),
    );
  }

  Widget _buildCommandBar({
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Add timesheet item',
          child: IconButton(
            icon: const Icon(FluentIcons.add),
            onPressed: () => timeTrackerProvider.addItem(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: TextBox(
            controller: _filterController,
            placeholder: 'Filter',
            onChanged: timeTrackerProvider.setFilter,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Send timesheet items to WTM',
          child: IconButton(
            icon: const Icon(FluentIcons.cloud_upload),
            onPressed: () async {
              await timeTrackerProvider.saveToWTM();
              await userConfigProvider.loadSubjectsAndCategories();
            },
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Clear all timesheet items',
          child: IconButton(
            icon: const Icon(FluentIcons.delete),
            onPressed: () {
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
        ),
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return PinnedFooterLayout(
      footerHeight: DurationFooter.reservedHeight,
      body: _buildItemList(
        timeTrackerProvider: timeTrackerProvider,
        userConfigProvider: userConfigProvider,
      ),
      footer: _buildFooter(context, timeTrackerProvider),
    );
  }

  Widget _buildItemList({
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsCategoriesProvider userConfigProvider,
  }) {
    return material.ReorderableListView(
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) async {
        if (timeTrackerProvider.hasFilter) {
          return;
        }
        await timeTrackerProvider.reorderItems(oldIndex, newIndex);
      },
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
    );
  }

  Widget _buildFooter(BuildContext context, TimetrackerProvider provider) {
    final theme = FluentTheme.of(context);
    final dividerColor = theme.resources.dividerStrokeColorDefault;

    return DurationFooter(
      durationByDate: provider.durationByDate,
      formatDate: (date) => DateFormat('d.M.').format(date),
      textStyle: theme.typography.body ?? const TextStyle(),
      emphasisTextStyle:
          theme.typography.bodyStrong ??
          const TextStyle(fontWeight: FontWeight.w600),
      dividerColor: dividerColor,
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
