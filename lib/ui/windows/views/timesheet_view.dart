import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/windows/infobar.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimesheetView extends StatefulWidget {
  const TimesheetView({super.key});

  @override
  State<TimesheetView> createState() => _TimesheetViewState();
}

class _TimesheetViewState extends State<TimesheetView> {
  static const double _dayPrefW = 40.0;
  static const double _datePickerPrefW = 120.0;
  static const double _timePickerPrefW = 80.0;
  static const double _durationPrefW = 80.0;
  static const double _spacingPrefW = 10.0;
  static const int _spacingCount = 7;

  bool _hasLoaded = false;
  final TextEditingController _filterController = TextEditingController();

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

  ({
    double dayW,
    double datePickerW,
    double timePickerW,
    double durationW,
    double spacingW,
  })
  _calculateLayoutDimensions(BoxConstraints constraints) {
    const fixedPrefTotal =
        _dayPrefW +
        _datePickerPrefW +
        _timePickerPrefW +
        _timePickerPrefW +
        _durationPrefW +
        _spacingPrefW * _spacingCount;
    final scale = ((constraints.maxWidth - 0.001) / fixedPrefTotal).clamp(
      0.0,
      1.0,
    );
    return (
      dayW: _dayPrefW * scale,
      datePickerW: _datePickerPrefW * scale,
      timePickerW: _timePickerPrefW * scale,
      durationW: _durationPrefW * scale,
      spacingW: _spacingPrefW * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TimesheetProvider>(
      builder: (context, provider, _) {
        if (provider.errorMsg != null) {
          final msg = provider.errorMsg!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            InfoBarManager.error(msg);
            provider.clearErrorMsg();
          });
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Timesheet'),
            commandBar: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --------------------------------------------------
                // From
                // --------------------------------------------------
                const Text('From'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: CalendarDatePicker(
                    initialStart: provider.fromDate,
                    onSelectionChanged: (calendarSelection) {
                      if (calendarSelection.startDate == null) {
                        return;
                      }
                      if (calendarSelection.startDate!.isAtSameMomentAs(
                        provider.fromDate,
                      )) {
                        return;
                      }
                      provider.setFromDate(calendarSelection.startDate!);
                      provider.loadTimesheetItems();
                    },
                    minDate: DateTime.now().subtract(const Duration(days: 365)),
                    firstDayOfWeek: DateTime.monday,
                    closeOnSelection: false,
                    dateFormatter: DateFormat('d.M.yyyy'),
                  ),
                ),
                const SizedBox(width: 8),
                // --------------------------------------------------
                // To
                // --------------------------------------------------
                const Text('To'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: CalendarDatePicker(
                    initialStart: provider.toDate,
                    onSelectionChanged: (calendarSelection) {
                      if (calendarSelection.startDate == null) {
                        return;
                      }
                      if (calendarSelection.startDate!.isAtSameMomentAs(
                        provider.toDate,
                      )) {
                        return;
                      }
                      provider.setToDate(calendarSelection.startDate!);
                      provider.loadTimesheetItems();
                    },
                    firstDayOfWeek: DateTime.monday,
                    closeOnSelection: false,
                    dateFormatter: DateFormat('d.M.yyyy'),
                  ),
                ),
                const SizedBox(width: 8),
                // --------------------------------------------------
                // Filter
                // --------------------------------------------------
                SizedBox(
                  width: 160,
                  child: TextBox(
                    controller: _filterController,
                    placeholder: 'Filter',
                    onChanged: (text) => provider.setFilter(text),
                  ),
                ),
                const SizedBox(width: 8),
                // --------------------------------------------------
                // Refresh
                // --------------------------------------------------
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
            ),
          ),
          content: _buildContent(context, provider),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TimesheetProvider provider) {
    if (!_hasLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasLoaded) {
          _hasLoaded = true;
          provider.loadTimesheetItems();
        }
      });
    }

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

    return Column(
      children: [
        // --------------------------------------------------
        // Header
        // --------------------------------------------------
        _buildHeader(context),
        // --------------------------------------------------
        // Items list
        // --------------------------------------------------
        Expanded(
          child: ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) =>
                _buildDataRow(context: context, item: provider.items[index]),
          ),
        ),
        // --------------------------------------------------
        // Footer summary
        // --------------------------------------------------
        _buildFooter(
          context,
          itemCount: provider.itemCount,
          totalDuration: provider.totalDuration,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFFE1E1E1))),
        color: const Color(0x0D000000),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final d = _calculateLayoutDimensions(constraints);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _headerCell(context, 'Day', d.dayW),
              SizedBox(width: d.spacingW),
              _headerCell(context, 'Date', d.datePickerW),
              SizedBox(width: d.spacingW),
              _headerCell(context, 'From', d.timePickerW),
              SizedBox(width: d.spacingW),
              _headerCell(context, 'To', d.timePickerW),
              SizedBox(width: d.spacingW),
              _headerCell(context, 'Worked', d.durationW),
              SizedBox(width: d.spacingW),
              Expanded(child: _headerCell(context, 'Subject', null)),
              SizedBox(width: d.spacingW),
              Expanded(child: _headerCell(context, 'Category', null)),
              SizedBox(width: d.spacingW),
              Expanded(child: _headerCell(context, 'Description', null)),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label, double? width) {
    final style =
        FluentTheme.of(
          context,
        ).typography.body?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontWeight: FontWeight.w600);
    final child = Text(label, style: style);
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }

  Widget _buildDataRow({
    required BuildContext context,
    required TimesheetItem item,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFFE1E1E1))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final d = _calculateLayoutDimensions(constraints);
          final locale = Localizations.localeOf(context).toString();
          final dayLabel = DateFormat('EEE', locale).format(item.from);
          final dateStr =
              '${item.from.year}-${item.from.month.toString().padLeft(2, '0')}-${item.from.day.toString().padLeft(2, '0')}';
          final fromStr =
              '${item.from.hour.toString().padLeft(2, '0')}:${item.from.minute.toString().padLeft(2, '0')}';
          final toStr =
              '${item.to.hour.toString().padLeft(2, '0')}:${item.to.minute.toString().padLeft(2, '0')}';
          final bodyStyle = FluentTheme.of(context).typography.body;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --------------------------------------------------
              // Day
              // --------------------------------------------------
              SizedBox(
                width: d.dayW,
                child: Text(dayLabel, style: bodyStyle),
              ),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // Date
              // --------------------------------------------------
              SizedBox(
                width: d.datePickerW,
                child: Text(dateStr, style: bodyStyle),
              ),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // From
              // --------------------------------------------------
              SizedBox(
                width: d.timePickerW,
                child: Text(fromStr, style: bodyStyle),
              ),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // To
              // --------------------------------------------------
              SizedBox(
                width: d.timePickerW,
                child: Text(toStr, style: bodyStyle),
              ),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // Worked
              // --------------------------------------------------
              SizedBox(
                width: d.durationW,
                child: Text(
                  toHmString(item.to.difference(item.from)),
                  style: bodyStyle,
                ),
              ),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // Subject
              // --------------------------------------------------
              Expanded(child: SelectableText(item.subject, style: bodyStyle)),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // Category
              // --------------------------------------------------
              Expanded(child: SelectableText(item.category, style: bodyStyle)),
              SizedBox(width: d.spacingW),
              // --------------------------------------------------
              // Description
              // --------------------------------------------------
              Expanded(
                child: SelectableText(item.description, style: bodyStyle),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required int itemCount,
    required Duration totalDuration,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: const Color(0xFFE1E1E1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Items: $itemCount'),
          const SizedBox(width: 8),
          Text('Worked: ${toHmString(totalDuration)}'),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
