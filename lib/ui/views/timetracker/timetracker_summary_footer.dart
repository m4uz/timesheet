import 'package:flutter/material.dart';
import 'package:timesheet/utils/duration_utils.dart';

class TimetrackerSummaryFooter extends StatelessWidget {
  const TimetrackerSummaryFooter({
    super.key,
    required this.durationByDate,
    required this.formatDate,
    required this.textStyle,
    required this.emphasisTextStyle,
    required this.dividerColor,
  });

  final List<({DateTime date, Duration duration})> durationByDate;
  final String Function(DateTime date) formatDate;
  final TextStyle textStyle;
  final TextStyle emphasisTextStyle;
  final Color dividerColor;

  Duration get _totalDuration =>
      durationByDate.fold(Duration.zero, (sum, entry) => sum + entry.duration);

  static const double reservedHeight = 36.0;

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[
      for (final entry in durationByDate)
        _FooterSegment(
          label: formatDate(entry.date),
          value: toHmString(entry.duration),
          textStyle: textStyle,
        ),
      _FooterSegment(
        label: 'Total',
        value: toHmString(_totalDuration),
        textStyle: textStyle,
        valueStyle: emphasisTextStyle,
        isTotal: true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < segments.length; i++) ...[
                  if (i > 0)
                    VerticalDivider(
                      width: 17,
                      thickness: 1,
                      color: dividerColor,
                    ),
                  segments[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterSegment extends StatelessWidget {
  const _FooterSegment({
    required this.label,
    required this.value,
    required this.textStyle,
    this.valueStyle,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final TextStyle textStyle;
  final TextStyle? valueStyle;
  final bool isTotal;

  TextStyle get _labelStyle => textStyle.copyWith(
    fontSize: (textStyle.fontSize ?? 14) - 1,
    color: textStyle.color?.withValues(alpha: 0.75),
  );

  TextStyle get _valueStyle => valueStyle ?? textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Align(
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _labelStyle),
            const SizedBox(width: 8),
            if (isTotal)
              SelectableText(value, style: _valueStyle)
            else
              Text(value, style: _valueStyle),
          ],
        ),
      ),
    );
  }
}
