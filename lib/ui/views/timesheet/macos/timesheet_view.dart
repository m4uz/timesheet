import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timesheet/providers/timesheet_provider.dart';
import 'package:timesheet/ui/platform/macos/calendar_toolbar_button.dart'
    as mac_calendar_toolbar_button;
import 'package:timesheet/ui/platform/snackbar.dart';
import 'package:timesheet/ui/platform/macos/toolbar_text_field.dart'
    as mac_toolbar_text_field;
import 'package:timesheet/ui/views/timesheet/macos/timesheet_table.dart';
import 'package:timesheet/ui/widgets/pinned_footer_layout.dart';
import 'package:timesheet/ui/views/timesheet/timesheet_summary_footer.dart';

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
        _scheduleInitialLoad(provider);
        _showProviderMessages(provider);

        return MacosScaffold(
          toolBar: _buildToolBar(context, provider),
          children: [
            ContentArea(
              builder: (context, scrollController) {
                return _buildContentArea(
                  context,
                  provider: provider,
                  scrollController: scrollController,
                );
              },
            ),
          ],
        );
      },
    );
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

  void _showProviderMessages(TimesheetProvider provider) {
    if (provider.errorMsg != null) {
      Snackbar.error(provider.errorMsg!);
      provider.clearErrorMsg();
    }
  }

  ToolBar _buildToolBar(BuildContext context, TimesheetProvider provider) {
    return ToolBar(
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
        mac_calendar_toolbar_button.CalendarToolbarButton(
          label: 'From',
          initialDateTime: provider.fromDate,
          minimumDateTime: DateTime.now().subtract(const Duration(days: 365)),
          maximumDateTime: DateTime.now().add(const Duration(days: 365)),
          onCompleted: (value) {
            if (value != null) {
              provider.setFromDate(value);
              provider.loadTimesheetItems();
            }
          },
        ),
        mac_calendar_toolbar_button.CalendarToolbarButton(
          label: 'To',
          initialDateTime: provider.toDate,
          minimumDateTime: DateTime.now().subtract(const Duration(days: 365)),
          maximumDateTime: DateTime.now().add(const Duration(days: 365)),
          onCompleted: (value) {
            if (value != null) {
              provider.setToDate(value);
              provider.loadTimesheetItems();
            }
          },
        ),
        mac_toolbar_text_field.ToolbarTextField(
          controller: _filterController,
          placeholder: 'Filter',
          onChanged: provider.setFilter,
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
    );
  }

  Widget _buildContentArea(
    BuildContext context, {
    required TimesheetProvider provider,
    required ScrollController scrollController,
  }) {
    if (provider.isLoading) {
      return const Center(child: ProgressCircle());
    }

    if (provider.items.isEmpty) {
      return Center(
        child: Text(
          'No timesheet items found',
          style: MacosTheme.of(context).typography.body,
        ),
      );
    }

    return PinnedFooterLayout(
      footerHeight: TimesheetSummaryFooter.reservedHeight,
      body: TimesheetTable(
        items: provider.items,
        scrollController: scrollController,
      ),
      footer: _buildFooter(context, provider),
    );
  }

  Widget _buildFooter(BuildContext context, TimesheetProvider provider) {
    final theme = MacosTheme.of(context);

    return TimesheetSummaryFooter(
      itemCount: provider.itemCount,
      totalDuration: provider.totalDuration,
      textStyle: theme.typography.body,
      dividerColor: theme.dividerColor,
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
