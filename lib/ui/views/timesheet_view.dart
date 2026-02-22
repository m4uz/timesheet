import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/snackbar.dart';
import 'package:timesheet/ui/cupertino_calendar_toolbar_button.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimeSheetView extends StatefulWidget {
  const TimeSheetView({super.key});

  @override
  State<TimeSheetView> createState() => _TimeSheetViewState();
}

class _TimeSheetViewState extends State<TimeSheetView> {
  static const double _dayPrefW = 40.0;
  static const double _datePickerPrefW = 120.0;
  static const double _timePickerPrefW = 80.0;
  static const double _durationPrefW = 80.0;
  static const double _spacingPrefW = 10.0;
  static const int _spacingCount = 7;

  bool _hasLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TimesheetProvider>(
      builder: (context, provider, _) {
        return MacosScaffold(
          toolBar: ToolBar(
            title: Text(
              'Timesheet',
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
              CupertinoCalendarPickerToolbarButton(
                label: 'From',
                initialDateTime: provider.fromDate,
                minimumDateTime: DateTime.now().subtract(
                  const Duration(days: 365),
                ),
                maximumDateTime: DateTime.now().add(const Duration(days: 365)),
                onCompleted: (value) {
                  if (value != null) {
                    provider.setFromDate(value);
                    provider.loadTimesheetItems();
                  }
                },
              ),
              CupertinoCalendarPickerToolbarButton(
                label: 'To',
                initialDateTime: provider.toDate,
                minimumDateTime: DateTime.now().subtract(
                  const Duration(days: 365),
                ),
                maximumDateTime: DateTime.now().add(const Duration(days: 365)),
                onCompleted: (value) {
                  if (value != null) {
                    provider.setToDate(value);
                    provider.loadTimesheetItems();
                  }
                },
              ),
              ToolBarIconButton(
                label: 'Refresh',
                showLabel: false,
                icon: const MacosIcon(CupertinoIcons.refresh_circled),
                tooltipMessage: 'Refresh timesheet items',
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.loadTimesheetItems(forceReload: true);
                      },
              ),
            ],
          ),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                // Load data on first load
                if (!_hasLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_hasLoaded) {
                      _hasLoaded = true;
                      provider.loadTimesheetItems();
                    }
                  });
                }

                if (provider.errorMsg != null) {
                  SnackBarManager.error(provider.errorMsg!);
                  provider.clearErrorMsg();
                }

                if (provider.isLoading) {
                  return Center(child: ProgressCircle());
                }

                if (provider.items.isEmpty) {
                  return Center(
                    child: Text(
                      'No timesheet items found',
                      style: MacosTheme.of(context).typography.body,
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: provider.items.length,
                        itemBuilder: (context, index) {
                          return _buildDataRow(
                            context: context,
                            item: provider.items[index],
                          );
                        },
                      ),
                    ),
                    _buildFooter(context, provider),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    const pad = EdgeInsets.all(10);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
        color: MacosTheme.of(context).brightness == Brightness.light
            ? const Color.fromRGBO(0, 0, 0, 0.05)
            : const Color.fromRGBO(255, 255, 255, 0.05),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimensions = _calculateLayoutDimensions(constraints);
          return _buildHeaderLayout(
            context: context,
            dayW: dimensions.dayW,
            datePickerW: dimensions.datePickerW,
            timePickerW: dimensions.timePickerW,
            durationW: dimensions.durationW,
            spacingW: dimensions.spacingW,
          );
        },
      ),
    );
  }

  Widget _buildHeaderLayout({
    required BuildContext context,
    required double dayW,
    required double datePickerW,
    required double timePickerW,
    required double durationW,
    required double spacingW,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: dayW,
          child: Text(
            'Day',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        SizedBox(
          width: datePickerW,
          child: Text(
            'Date',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        SizedBox(
          width: timePickerW,
          child: Text(
            'From',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        SizedBox(
          width: timePickerW,
          child: Text(
            'To',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        SizedBox(
          width: durationW,
          child: Text(
            'Worked',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        Expanded(
          child: Text(
            'Subject',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        Expanded(
          child: Text(
            'Category',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: spacingW),
        Expanded(
          child: Text(
            'Description',
            style: MacosTheme.of(
              context,
            ).typography.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow({
    required BuildContext context,
    required TimesheetItem item,
  }) {
    const pad = EdgeInsets.all(10);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dimensions = _calculateLayoutDimensions(constraints);
          return _buildRowLayout(
            context: context,
            dayW: dimensions.dayW,
            datePickerW: dimensions.datePickerW,
            timePickerW: dimensions.timePickerW,
            durationW: dimensions.durationW,
            spacingW: dimensions.spacingW,
            item: item,
          );
        },
      ),
    );
  }

  Widget _buildRowLayout({
    required BuildContext context,
    required double dayW,
    required double datePickerW,
    required double timePickerW,
    required double durationW,
    required double spacingW,
    required TimesheetItem item,
  }) {
    final locale = Localizations.localeOf(context).toString();
    final dayLabel = DateFormat('EEE', locale).format(item.from);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --------------------------------------------------
        // Day
        // --------------------------------------------------
        SizedBox(
          width: dayW,
          child: Text(
            dayLabel,
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // Date
        // --------------------------------------------------
        SizedBox(
          width: datePickerW,
          child: Text(
            '${item.from.year}-${item.from.month.toString().padLeft(2, '0')}-${item.from.day.toString().padLeft(2, '0')}',
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // From
        // --------------------------------------------------
        SizedBox(
          width: timePickerW,
          child: Text(
            '${item.from.hour.toString().padLeft(2, '0')}:${item.from.minute.toString().padLeft(2, '0')}',
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // To
        // --------------------------------------------------
        SizedBox(
          width: timePickerW,
          child: Text(
            '${item.to.hour.toString().padLeft(2, '0')}:${item.to.minute.toString().padLeft(2, '0')}',
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // Worked
        // --------------------------------------------------
        SizedBox(
          width: durationW,
          child: Text(
            toHmString(item.to.difference(item.from)),
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // Subject
        // --------------------------------------------------
        Expanded(
          child: SelectableText(
            item.subject,
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // Category
        // --------------------------------------------------
        Expanded(
          child: SelectableText(
            item.category,
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
        SizedBox(width: spacingW),
        // --------------------------------------------------
        // Description
        // --------------------------------------------------
        Expanded(
          child: SelectableText(
            item.description,
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
      ],
    );
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

  Widget _buildFooter(BuildContext context, TimesheetProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Items: ${provider.itemCount}',
            style: MacosTheme.of(context).typography.body,
          ),
          SizedBox(width: 8),
          SelectableText(
            'Worked: ${toHmString(provider.totalDuration)}',
            style: MacosTheme.of(context).typography.body,
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
