import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart' hide Dialog;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/subjects_and_categories_provider.dart';
import 'package:timesheet/providers/timetracker_provider.dart';
import 'package:timesheet/ui/platform/dialog.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/platform/linux/toolbar_filter_field.dart';
import 'package:timesheet/ui/platform/linux/toolbar_icon_button.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timetracker/linux/timetracker_item_row.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_summary_footer.dart';
import 'package:timesheet/ui/views/timetracker/timetracker_tab_navigation.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';
import 'package:yaru/yaru.dart';

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

        return Scaffold(
          appBar: _buildAppBar(
            context,
            timeTrackerProvider: timeTrackerProvider,
            userConfigProvider: userConfigProvider,
          ),
          body: _buildContentArea(
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    return YaruWindowTitleBar(
      border: BorderSide.none,
      title: const Text('Timetracker'),
      actions: [
        ToolbarIconButton(
          message: 'Add timesheet item',
          icon: YaruIcons.plus,
          onPressed: () => timeTrackerProvider.addItem(),
        ),
        const SizedBox(width: LinuxLayout.space8),
        ToolbarFilterField(
          controller: _filterController,
          hintText: 'Filter',
          onChanged: timeTrackerProvider.setFilter,
        ),
        const SizedBox(width: LinuxLayout.space8),
        ToolbarIconButton(
          message: 'Send timesheet items to WTM',
          icon: YaruIcons.network_transmit,
          onPressed: () async {
            await timeTrackerProvider.saveToWTM();
            await userConfigProvider.loadSubjectsAndCategories();
          },
        ),
        const SizedBox(width: LinuxLayout.space8),
        ToolbarIconButton(
          message: 'Clear all timesheet items',
          icon: YaruIcons.trash,
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
        const SizedBox(width: LinuxLayout.space8),
      ],
    );
  }

  Widget _buildContentArea(
    BuildContext context, {
    required TimetrackerProvider timeTrackerProvider,
    required SubjectsAndCategoriesProvider userConfigProvider,
  }) {
    if (userConfigProvider.isLoading) {
      return const Center(child: YaruCircularProgressIndicator());
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
    final theme = Theme.of(context);
    _rowKeys.pruneTo(timeTrackerProvider.items.map((e) => e.id));

    return ReorderableListView(
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(animation.value);
            final elevation = lerpDouble(0, 8, t)!;
            return Material(
              color: theme.scaffoldBackgroundColor,
              elevation: elevation,
              shadowColor: Colors.black.withValues(alpha: 0.18 * t),
              child: child,
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
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium ?? const TextStyle();

    return TimetrackerSummaryFooter(
      durationByDate: provider.durationByDate,
      formatDate: (date) => DateFormat('d.M.').format(date),
      textStyle: bodyStyle,
      emphasisTextStyle: bodyStyle.copyWith(fontWeight: FontWeight.w600),
      dividerColor: LinuxLayout.dividerColor(theme),
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
