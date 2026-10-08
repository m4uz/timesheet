// Adapted from Yaru's YaruEdgeFocusInterceptor
// (https://github.com/ubuntu/yaru.dart), MIT License.

import 'package:flutter/widgets.dart';

/// Focus sentinels before/after [child] so entering the field from either
/// direction can select the first or last segment.
class EdgeFocusInterceptor extends StatefulWidget {
  const EdgeFocusInterceptor({
    super.key,
    required this.child,
    required this.onFocusFromPreviousNode,
    required this.onFocusFromNextNode,
  });

  final Widget child;
  final VoidCallback onFocusFromPreviousNode;
  final VoidCallback onFocusFromNextNode;

  @override
  State<EdgeFocusInterceptor> createState() => _EdgeFocusInterceptorState();
}

class _EdgeFocusInterceptorState extends State<EdgeFocusInterceptor> {
  late final FocusNode _outerFocusNode;
  late final FocusNode _previousFocusNode;
  late final FocusNode _nextFocusNode;

  @override
  void initState() {
    super.initState();
    _outerFocusNode = FocusNode()..addListener(_rebuild);
    _previousFocusNode = FocusNode()..addListener(_rebuild);
    _nextFocusNode = FocusNode()..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _outerFocusNode.dispose();
    _previousFocusNode.dispose();
    _nextFocusNode.dispose();
    super.dispose();
  }

  Widget _edge({required bool previous, required VoidCallback callback}) {
    return Focus(
      focusNode: previous ? _previousFocusNode : _nextFocusNode,
      canRequestFocus: !_outerFocusNode.hasFocus,
      onFocusChange: (hasFocus) {
        if (!hasFocus) return;
        // Callback selects first/last segment and requestFocuses the field.
        // Do not call nextFocus/previousFocus afterward: that moves past the
        // already-focused field onto the opposite sentinel and freezes in a loop.
        callback();
      },
      child: const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _outerFocusNode,
      canRequestFocus: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _edge(previous: true, callback: widget.onFocusFromPreviousNode),
          widget.child,
          _edge(previous: false, callback: widget.onFocusFromNextNode),
        ],
      ),
    );
  }
}
