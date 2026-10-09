import 'package:flutter/widgets.dart';

/// Shared layout metrics for segmented date/time fields (macOS + Windows + Linux).
class SegmentedFieldMetrics {
  SegmentedFieldMetrics._();

  static const double segmentClusterWidth = 42;

  /// `DD.MM.` needs slightly more room than `HH:mm`.
  static const double dateSegmentClusterWidth = 50;

  /// Typed date segments plus calendar overlay button.
  static const double dateColumnWidth = 86;

  /// Typed `HH:mm` plus clock overlay button.
  static const double timeColumnWidth = 78;

  static const EdgeInsets fieldWithButtonPadding = EdgeInsets.only(
    left: 6,
    right: 2,
    top: 2,
    bottom: 2,
  );
}
