import 'package:flutter/material.dart';

class PinnedFooterLayout extends StatelessWidget {
  const PinnedFooterLayout({
    super.key,
    required this.body,
    required this.footer,
    required this.footerHeight,
  });

  final Widget body;
  final Widget footer;
  final double footerHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedFooterHeight = footerHeight.clamp(
          0.0,
          constraints.maxHeight,
        );

        return Column(
          children: [
            Expanded(child: body),
            SizedBox(
              height: clampedFooterHeight,
              child: ClipRect(child: footer),
            ),
          ],
        );
      },
    );
  }
}
