// Adapted from Yaru's YaruSegmentedEntry
// (https://github.com/ubuntu/yaru.dart), MIT License.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timesheet/ui/widgets/segmented_entry/edge_focus_interceptor.dart';
import 'package:timesheet/ui/widgets/segmented_entry/entry_segment.dart';

/// An entry split into selectable editable segments with keyboard navigation.
class SegmentedEntry extends StatefulWidget {
  const SegmentedEntry({
    super.key,
    required this.segments,
    required this.delimiters,
    this.focusNode,
    this.autofocus = false,
    this.controller,
    this.style,
    this.cursorColor,
    this.onChanged,
    this.onFocusLost,
    this.keyboardType,
    this.enabled = true,
  }) : assert(
         delimiters.length == segments.length - 1 ||
             delimiters.length == segments.length ||
             (segments.length == 0 && delimiters.length == 0),
       );

  final List<EntrySegment> segments;

  /// Delimiters between segments. Length may be `segments.length - 1`
  /// (between only) or `segments.length` (trailing delimiter after the last
  /// segment, e.g. German `d.M.`).
  final List<String?> delimiters;
  final FocusNode? focusNode;
  final bool autofocus;
  final SegmentedEntryController? controller;
  final TextStyle? style;
  final Color? cursorColor;
  final ValueChanged<String>? onChanged;

  /// Called when the field loses focus (commit / restore hook).
  final VoidCallback? onFocusLost;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  SegmentedEntryState createState() => SegmentedEntryState();
}

class SegmentedEntryState extends State<SegmentedEntry> {
  bool _initialized = false;

  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode!;

  SegmentedEntryController? _internalController;
  SegmentedEntryController get _controller =>
      widget.controller ?? _internalController!;

  final _textEditingController = TextEditingController();

  EntrySegment get _selectedSegment => widget.segments[_controller.index];

  /// Focus this field and select segment [index] (clamped).
  void focusSegment(int index) {
    if (widget.segments.isEmpty) return;
    final clamped = index.clamp(0, widget.segments.length - 1);
    _controller.index = clamped;
    _focusNode.requestFocus();
    _updateTextEditingValue();
  }

  @override
  void initState() {
    super.initState();
    _attachFocusNode();
    _attachController();
    _controller.addListener(_controllerCallback);
    _init();
  }

  @override
  void didUpdateWidget(covariant SegmentedEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialized) {
      for (final segment in oldWidget.segments) {
        segment.removeListener(_segmentCallback);
      }
      for (final segment in widget.segments) {
        segment.addListener(_segmentCallback);
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      _detachFocusNode(oldWidget.focusNode);
      _attachFocusNode();
    } else if (widget.enabled != oldWidget.enabled) {
      _focusNode.canRequestFocus = widget.enabled;
      _focusNode.skipTraversal = !widget.enabled;
    }

    if (widget.segments.length != oldWidget.segments.length ||
        widget.controller != oldWidget.controller) {
      _controller.removeListener(_controllerCallback);
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _attachController();
      _controller.addListener(_controllerCallback);
      _updateTextEditingValue();
    }
  }

  @override
  void dispose() {
    for (final segment in widget.segments) {
      segment.removeListener(_segmentCallback);
    }
    _textEditingController.removeListener(_textEditingControllerCallback);
    _controller.removeListener(_controllerCallback);
    _textEditingController.dispose();
    _detachFocusNode(widget.focusNode);
    _internalFocusNode?.dispose();
    if (widget.controller == null) {
      _internalController?.dispose();
    }
    super.dispose();
  }

  void _init() {
    if (_initialized) return;
    _initialized = true;
    for (final segment in widget.segments) {
      segment.addListener(_segmentCallback);
    }
    _updateTextEditingValue();
    _textEditingController.addListener(_textEditingControllerCallback);
  }

  void _attachFocusNode() {
    if (widget.focusNode == null) {
      _internalFocusNode ??= FocusNode();
    } else {
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }
    _focusNode.onKeyEvent = _onKeyEvent;
    _focusNode.addListener(_onFocusChanged);
    _focusNode.canRequestFocus = widget.enabled;
    _focusNode.skipTraversal = !widget.enabled;
  }

  void _detachFocusNode(FocusNode? external) {
    final node = external ?? _internalFocusNode;
    node?.onKeyEvent = null;
    node?.removeListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      widget.onFocusLost?.call();
    }
  }

  void _attachController() {
    if (widget.controller == null) {
      _internalController ??= SegmentedEntryController(
        length: widget.segments.length,
      );
    } else {
      _internalController?.dispose();
      _internalController = null;
    }
  }

  void _updateTextEditingValue() {
    final oldText = _textEditingController.value.text;
    _textEditingController.value = _getTextEditingValue();
    if (_textEditingController.value.text != oldText) {
      widget.onChanged?.call(_textEditingController.value.text);
    }
  }

  void _segmentCallback() => _updateTextEditingValue();

  void _controllerCallback() {
    _updateTextEditingValue();
    for (final segment in widget.segments) {
      segment.onSelect(false);
    }
    if (widget.segments.isNotEmpty) {
      _selectedSegment.onSelect(true);
    }
  }

  void _textEditingControllerCallback() {
    final selection = _textEditingController.selection.start;

    for (var i = 0; i < widget.segments.length; i++) {
      final baseOffset = _getBaseOffsetOfIndex(i);
      final extentOffset = _getExtentOffsetOfIndex(i);
      final isLastSegment = i == widget.segments.length - 1;
      final delimiterLength = !isLastSegment
          ? _getDelimiterOfIndex(i).length
          : 1;

      if (selection >= baseOffset &&
          selection < extentOffset + delimiterLength) {
        _controller.index = i;
        _updateTextEditingValue();
        break;
      }
    }
  }

  void _onFocusFromEdge({required bool previous, required bool ltr}) {
    if (previous && ltr || !previous && !ltr) {
      _controller.selectFirstSegment();
    } else {
      _controller.selectLastSegment();
    }
    _focusNode.requestFocus();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (widget.segments.isEmpty ||
        !(event is KeyDownEvent || event is KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }

    final ltr = Directionality.of(context) == TextDirection.ltr;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final tab = event.logicalKey == LogicalKeyboardKey.tab && !isShiftPressed;
    final shiftTab =
        event.logicalKey == LogicalKeyboardKey.tab && isShiftPressed;
    final arrowLeft = event.logicalKey == LogicalKeyboardKey.arrowLeft;
    final arrowRight = event.logicalKey == LogicalKeyboardKey.arrowRight;

    final left = (ltr ? shiftTab : tab) || arrowLeft;
    final right = (ltr ? tab : shiftTab) || arrowRight;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final backspace = event.logicalKey == LogicalKeyboardKey.backspace;

    late final SegmentEventReturnAction action;

    if (left) {
      action = _controller.maybeSelectPreviousSegment()
          ? SegmentEventReturnAction.handled
          : SegmentEventReturnAction.ignored;
    } else if (right) {
      action = _controller.maybeSelectNextSegment()
          ? SegmentEventReturnAction.handled
          : SegmentEventReturnAction.ignored;
    } else if (up) {
      action = _selectedSegment.onUpArrowKey();
    } else if (down) {
      action = _selectedSegment.onDownArrowKey();
    } else if (backspace) {
      action = _selectedSegment.onBackspaceKey();
    } else {
      action = SegmentEventReturnAction.ignored;
    }

    switch (action) {
      case SegmentEventReturnAction.selectPreviousSegment:
        _controller.maybeSelectPreviousSegment();
      case SegmentEventReturnAction.selectNextSegment:
        _controller.maybeSelectNextSegment();
      case SegmentEventReturnAction.handled:
        break;
      case SegmentEventReturnAction.ignored:
        // Let focus traversal leave the field at the edges (Tab → next control).
        return KeyEventResult.ignored;
    }

    _focusNode.requestFocus();
    return KeyEventResult.handled;
  }

  TextEditingValue _getTextEditingValue() {
    var text = '';
    for (var i = 0; i < widget.segments.length; i++) {
      text += widget.segments[i].text + _getDelimiterOfIndex(i);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: _getBaseOffsetOfIndex(_controller.index),
        extentOffset: _getExtentOffsetOfIndex(_controller.index),
      ),
    );
  }

  String _getDelimiterOfIndex(int index) {
    if (index < widget.delimiters.length) {
      return widget.delimiters[index] ?? '';
    }
    return '';
  }

  String _getPrefixOfIndex(int index) {
    if (index == 0) return '';
    var prefix = '';
    for (var i = 0; i < index; i++) {
      prefix += widget.segments[i].text + _getDelimiterOfIndex(i);
    }
    return prefix;
  }

  String _getSuffixOfIndex(int index) {
    if (index >= widget.segments.length) return '';
    var suffix = _getDelimiterOfIndex(index);
    for (var i = index + 1; i < widget.segments.length; i++) {
      suffix += widget.segments[i].text + _getDelimiterOfIndex(i);
    }
    return suffix;
  }

  int _getBaseOffsetOfIndex(int index) {
    if (index == 0 || widget.segments.isEmpty) return 0;
    var baseOffset = 0;
    for (var i = 0; i < index; i++) {
      baseOffset += widget.segments[i].length + _getDelimiterOfIndex(i).length;
    }
    return baseOffset;
  }

  int _getExtentOffsetOfIndex(int index) {
    return widget.segments.isNotEmpty
        ? _getBaseOffsetOfIndex(index) + widget.segments[index].length
        : 0;
  }

  TextEditingValue _valueFormatter(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (widget.segments.isEmpty) {
      return TextEditingValue.empty;
    }

    final prefix = _getPrefixOfIndex(_controller.index);
    final suffix = _getSuffixOfIndex(_controller.index);
    final input = newValue.text
        .replaceFirst(prefix, '')
        .replaceFirst(suffix, '');

    final action = _selectedSegment.onInput(input);
    switch (action) {
      case SegmentEventReturnAction.selectPreviousSegment:
        _controller.maybeSelectPreviousSegment();
      case SegmentEventReturnAction.selectNextSegment:
        _controller.maybeSelectNextSegment();
      default:
        break;
    }

    return _getTextEditingValue();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final effectiveStyle = widget.style ?? defaultStyle;
    final ltr = Directionality.of(context) == TextDirection.ltr;

    // Keep edge-focus sentinels in their own traversal group so their
    // below-the-field geometry cannot sort after later row controls
    // (e.g. subject) under ReadingOrderTraversalPolicy.
    return FocusTraversalGroup(
      child: EdgeFocusInterceptor(
        onFocusFromPreviousNode: () =>
            _onFocusFromEdge(previous: true, ltr: ltr),
        onFocusFromNextNode: () => _onFocusFromEdge(previous: false, ltr: ltr),
        // Material TextField (not MacosTextField): macos_ui's field swallows Tab
        // before FocusNode.onKeyEvent, so segment navigation breaks.
        child: Material(
          type: MaterialType.transparency,
          child: TextField(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            readOnly: !widget.enabled,
            controller: _textEditingController,
            style: effectiveStyle,
            cursorColor: widget.cursorColor,
            keyboardType: widget.keyboardType ?? TextInputType.datetime,
            showCursor: false,
            enableInteractiveSelection: widget.enabled,
            mouseCursor: _initialized ? SystemMouseCursors.basic : null,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            inputFormatters: [TextInputFormatter.withFunction(_valueFormatter)],
          ),
        ),
      ),
    );
  }
}
