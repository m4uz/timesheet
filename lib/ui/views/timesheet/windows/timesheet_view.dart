import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_summary_footer.dart';
import 'package:timesheet/ui/views/timesheet/windows/timesheet_table.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';

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

        return ScaffoldPage(
          header: _buildPageHeader(context, provider),
          content: _buildContentArea(context, provider),
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

  PageHeader _buildPageHeader(BuildContext context, TimesheetProvider provider) {
    return PageHeader(
      title: const Text('Timesheet'),
      commandBar: _buildCommandBar(provider),
    );
  }

  Widget _buildCommandBar(TimesheetProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('From'),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: CalendarDatePicker(
            initialStart: provider.fromDate,
            onSelectionChanged: (calendarSelection) {
              final date = calendarSelection.startDate;
              if (date == null || date.isAtSameMomentAs(provider.fromDate)) {
                return;
              }
              provider.setFromDate(date);
              provider.loadTimesheetItems();
            },
            minDate: DateTime.now().subtract(const Duration(days: 365)),
            firstDayOfWeek: DateTime.monday,
            closeOnSelection: false,
            dateFormatter: DateFormat('d.M.yyyy'),
          ),
        ),
        const SizedBox(width: 8),
        const Text('To'),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: CalendarDatePicker(
            initialStart: provider.toDate,
            onSelectionChanged: (calendarSelection) {
              final date = calendarSelection.startDate;
              if (date == null || date.isAtSameMomentAs(provider.toDate)) {
                return;
              }
              provider.setToDate(date);
              provider.loadTimesheetItems();
            },
            firstDayOfWeek: DateTime.monday,
            closeOnSelection: false,
            dateFormatter: DateFormat('d.M.yyyy'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 160,
          child: TextBox(
            controller: _filterController,
            placeholder: 'Filter',
            onChanged: provider.setFilter,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Refresh timesheet items',
          child: IconButton(
            icon: const Icon(FluentIcons.refresh),
            onPressed: provider.isLoading
                ? null
                : () => provider.loadTimesheetItems(forceReload: true),
          ),
        ),
      ],
    );
  }

  Widget _buildContentArea(BuildContext context, TimesheetProvider provider) {
    _scheduleInitialLoad(provider);

    if (provider.isLoading) {
      return const Center(child: ProgressRing());
    }

    if (provider.items.isEmpty) {
      return Center(
        child: Text(
          'No timesheet items found',
          style: FluentTheme.of(context).typography.body,
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
        textStyle: FluentTheme.of(context).typography.body ?? const TextStyle(),
        dividerColor:
            FluentTheme.of(context).resources.dividerStrokeColorDefault,
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
