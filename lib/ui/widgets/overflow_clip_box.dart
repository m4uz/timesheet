import 'dart:math' as math;

import 'package:flutter/material.dart';

class OverflowClipBox extends StatelessWidget {
  const OverflowClipBox({
    super.key,
    required this.axis,
    required this.minExtent,
    required this.childBuilder,
  });

  final Axis axis;
  final double minExtent;
  final Widget Function(double extent) childBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = axis == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final extent = math.max(available, minExtent);

        return ClipRect(
          child: SingleChildScrollView(
            scrollDirection: axis,
            physics: const NeverScrollableScrollPhysics(),
            child: childBuilder(extent),
          ),
        );
      },
    );
  }
}
