import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/platform/linux/linux_layout.dart';
import 'package:timesheet/ui/platform/linux/toolbar_filter_field.dart';
import 'package:timesheet/ui/platform/linux/toolbar_icon_button.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timesheet/linux/timesheet_table.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_summary_footer.dart';
import 'package:timesheet/ui/widgets/linux_date_entry.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';
import 'package:yaru/yaru.dart';

class TimesheetView extends StatefulWidget {
  const TimesheetView({super.key});

  @override
  State<TimesheetView> createState() => _TimesheetViewState();
}

class _TimesheetViewState extends State<TimesheetView> {
  bool _hasLoaded = false;
  final TextEditingController _filterController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<TimesheetProvider>(
      builder: (context, provider, _) {
        _showProviderMessages(provider);

        return Scaffold(
          appBar: _buildAppBar(context, provider),
          body: _buildContentArea(context, provider),
        );
      },
    );
  }

  void _showProviderMessages(TimesheetProvider provider) {
    if (provider.errorMsg == null) {
      return;
    }
    final msg = provider.errorMsg!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Snackbar.error(msg);
      provider.clearErrorMsg();
    });
  }

  void _scheduleInitialLoad(TimesheetProvider provider) {
    if (_hasLoaded) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded) {
        _hasLoaded = true;
        provider.loadTimesheetItems();
      }
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TimesheetProvider provider,
  ) {
    final theme = Theme.of(context);
    final labelStyle = LinuxLayout.toolbarLabelStyle(theme);
    final minimumDate = DateTime.now().subtract(const Duration(days: 365));
    final maximumDate = DateTime.now().add(const Duration(days: 365));

    return YaruWindowTitleBar(
      border: BorderSide.none,
      title: const Text('Timesheet'),
      actions: [
        Text('From', style: labelStyle),
        const SizedBox(width: LinuxLayout.space8),
        SizedBox(
          width: LinuxLayout.dateTimeColumnWidth,
          child: LinuxDateEntry(
            date: provider.fromDate,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            style: LinuxLayout.rowFieldStyle(theme),
            semanticLabel: 'From',
            calendarSemanticLabel: 'Open from calendar',
            onChanged: (value) {
              provider.setFromDate(value);
              provider.loadTimesheetItems();
            },
          ),
        ),
        const SizedBox(width: LinuxLayout.space8),
        Text('To', style: labelStyle),
        const SizedBox(width: LinuxLayout.space8),
        SizedBox(
          width: LinuxLayout.dateTimeColumnWidth,
          child: LinuxDateEntry(
            date: provider.toDate,
            minimumDate: minimumDate,
            maximumDate: maximumDate,
            style: LinuxLayout.rowFieldStyle(theme),
            semanticLabel: 'To',
            calendarSemanticLabel: 'Open to calendar',
            onChanged: (value) {
              provider.setToDate(value);
              provider.loadTimesheetItems();
            },
          ),
        ),
        const SizedBox(width: LinuxLayout.space8),
        ToolbarFilterField(
          controller: _filterController,
          hintText: 'Filter',
          onChanged: provider.setFilter,
        ),
        const SizedBox(width: LinuxLayout.space8),
        ToolbarIconButton(
          message: 'Refresh timesheet items',
          icon: YaruIcons.refresh,
          onPressed: provider.isLoading
              ? null
              : () => provider.loadTimesheetItems(forceReload: true),
        ),
        const SizedBox(width: LinuxLayout.space8),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context, TimesheetProvider provider) {
    _scheduleInitialLoad(provider);

    if (provider.isLoading) {
      return const Center(child: YaruCircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return Center(
        child: Text(
          'No timesheet items found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return PinnedFooterLayout(
      footerHeight: TimesheetSummaryFooter.reservedHeight,
      body: TimesheetTable(
        items: provider.items,
        visibleColumns: provider.visibleColumns,
      ),
      footer: TimesheetSummaryFooter(
        itemCount: provider.itemCount,
        totalDuration: provider.totalDuration,
        textStyle: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        dividerColor: LinuxLayout.dividerColor(Theme.of(context)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _filterController.text = context.read<TimesheetProvider>().filter;
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }
}
