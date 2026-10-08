import 'dart:ui' show lerpDouble;

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/platform/windows/command_bar_icon_button.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/views/timetracker/windows/timetracker_item_row.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_summary_footer.dart';
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
      builder: (context, timeTrackerProvider, userConfigProvider, _) {
        _showProviderMessages(timeTrackerProvider, userConfigProvider);

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

  void _showProviderMessages(
    TimetrackerProvider timeTrackerProvider,
    SubjectsAndCategoriesProvider userConfigProvider,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    });
  }

  PageHeader _buildPageHeader(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
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
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommandBarIconButton(
          message: 'Add timesheet item',
          icon: FluentIcons.add,
          onPressed: () => timeTrackerProvider.addItem(),
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
        CommandBarIconButton(
          message: 'Send timesheet items to WTM',
          icon: FluentIcons.cloud_upload,
          onPressed: () async {
            await timeTrackerProvider.saveToWTM();
            await userConfigProvider.loadSubjectsAndCategories();
          },
        ),
        const SizedBox(width: 8),
        CommandBarIconButton(
          message: 'Clear all timesheet items',
          icon: FluentIcons.delete,
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
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    if (userConfigProvider.isLoading) {
      return const Center(child: ProgressRing());
    }
    return PinnedFooterLayout(
      footerHeight: TimetrackerSummaryFooter.reservedHeight,
      body: _buildItemList(
        timeTrackerProvider: timeTrackerProvider,
        userConfigProvider: userConfigProvider,
      ),
      footer: _buildFooter(context, timeTrackerProvider),
    );
  }

  Widget _buildItemList({
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    final theme = FluentTheme.of(context);
    _rowKeys.pruneTo(timeTrackerProvider.items.map((e) => e.id));

    return material.ReorderableListView(
      buildDefaultDragHandles: false,
      // Skip Material's default proxy (wraps in Material + inherit:true
      // DefaultTextStyle). Keep FluentTheme and a light lift shadow instead.
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            final elevation = lerpDouble(0, 8, t)!;
            return FluentTheme(
              data: theme,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: material.Colors.black.withValues(alpha: 0.18 * t),
                      blurRadius: elevation,
                      offset: Offset(0, elevation / 2),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      onReorderItem: (oldIndex, newIndex) async {
        if (timeTrackerProvider.hasFilter) {
          return;
        }
        await timeTrackerProvider.reorderItems(oldIndex, newIndex);
      },
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
    );
  }

  Widget _buildFooter(BuildContext context, TimetrackerProvider provider) {
    final theme = FluentTheme.of(context);
    final dividerColor = theme.resources.dividerStrokeColorDefault;

    return TimetrackerSummaryFooter(
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
