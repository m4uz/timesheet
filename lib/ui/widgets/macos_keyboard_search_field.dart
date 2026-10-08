import 'package:flutter/cupertino.dart' hide OverlayVisibilityMode;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

const BorderRadius _kBorderRadius = BorderRadius.all(Radius.circular(7.0));
const double _kResultHeight = 20.0;
const double _kResultsOverlayMargin = 12.0;

/// macOS-styled search field with keyboard navigation over results.
///
/// Arrow ↑/↓ move the highlight, Enter selects, Escape dismisses. Mouse click
/// still works. Adapted from [MacosSearchField] plus Fluent-style key handling.
class MacosKeyboardSearchField extends StatefulWidget {
  const MacosKeyboardSearchField({
    super.key,
    required this.results,
    this.onResultSelected,
    this.maxResultsToShow = 10,
    this.resultHeight = _kResultHeight,
    this.controller,
    this.focusNode,
    this.placeholder = 'Search',
    this.style,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
  });

  final List<SearchResultItem> results;
  final ValueChanged<SearchResultItem>? onResultSelected;
  final int maxResultsToShow;
  final double resultHeight;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLines;

  @override
  State<MacosKeyboardSearchField> createState() =>
      MacosKeyboardSearchFieldState();
}

class MacosKeyboardSearchFieldState extends State<MacosKeyboardSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;
  late final bool _ownsFocusNode;

  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();

  OverlayEntry? _overlayEntry;
  List<SearchResultItem> _filtered = const [];
  int _highlightedIndex = -1;
  bool _overlayAbove = false;

  bool get _isOverlayVisible => _overlayEntry != null;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.onKeyEvent = _onKeyEvent;
    _focusNode.addListener(_onFocusChanged);
    _filtered = _filter(_controller.text);
  }

  @override
  void didUpdateWidget(covariant MacosKeyboardSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.results != oldWidget.results) {
      _filtered = _filter(_controller.text);
      if (_filtered.isEmpty) {
        if (_overlayEntry != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _removeOverlay();
          });
        }
        return;
      }
      if (_highlightedIndex >= _filtered.length) {
        _highlightedIndex = _filtered.length - 1;
      }
      // Parent rebuilds (e.g. provider notify) run during build — defer.
      _scheduleOverlayRefresh();
    }
  }

  @override
  void dispose() {
    _focusNode.onKeyEvent = null;
    _focusNode.removeListener(_onFocusChanged);
    _removeOverlay();
    _scrollController.dispose();
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  List<SearchResultItem> _filter(String query) {
    final q = query.trim().toLowerCase();
    final matches = q.isEmpty
        ? List<SearchResultItem>.from(widget.results)
        : widget.results
              .where((item) => item.searchKey.toLowerCase().contains(q))
              .toList();
    if (matches.length > widget.maxResultsToShow) {
      return matches.sublist(0, widget.maxResultsToShow);
    }
    return matches;
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _filtered = _filter(_controller.text);
    if (_filtered.isEmpty) return;
    _highlightedIndex = -1;
    _overlayAbove = _shouldPlaceOverlayAbove(_filtered.length);
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _highlightedIndex = -1;
  }

  void _refreshOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _scheduleOverlayRefresh() {
    if (_overlayEntry == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overlayEntry == null) return;
      _overlayEntry!.markNeedsBuild();
    });
  }

  void _onQueryChanged(String query) {
    _filtered = _filter(query);
    _highlightedIndex = -1;
    if (_filtered.isEmpty) {
      _removeOverlay();
    } else if (_focusNode.hasFocus && !_isOverlayVisible) {
      _showOverlay();
    } else if (_isOverlayVisible) {
      _overlayAbove = _shouldPlaceOverlayAbove(_filtered.length);
      _refreshOverlay();
    }
    widget.onChanged?.call(query);
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= _filtered.length) return;
    final item = _filtered[index];
    item.onSelected?.call();
    widget.onResultSelected?.call(item);
    _removeOverlay();
  }

  void _moveHighlight(int delta) {
    if (_filtered.isEmpty) return;
    if (!_isOverlayVisible) {
      _showOverlay();
    }
    final last = _filtered.length - 1;
    if (_highlightedIndex < 0) {
      _highlightedIndex = delta > 0 ? 0 : last;
    } else {
      _highlightedIndex = (_highlightedIndex + delta).clamp(0, last);
    }
    _refreshOverlay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _overlayEntry == null ||
          !_scrollController.hasClients) {
        return;
      }
      final offset = _highlightedIndex * widget.resultHeight;
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_isOverlayVisible) {
        _removeOverlay();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_highlightedIndex >= 0) {
        _selectIndex(_highlightedIndex);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return KeyEventResult.ignored;
  }

  bool _shouldPlaceOverlayAbove(int resultCount) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final overlayHeight =
        resultCount * widget.resultHeight + _kResultsOverlayMargin;
    final global = box.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final spaceBelow = screenHeight - (global.dy + box.size.height);
    return spaceBelow < overlayHeight + widget.resultHeight;
  }

  Offset _overlayOffset(Size fieldSize, int resultCount) {
    if (!_overlayAbove) return Offset(0, fieldSize.height);
    final overlayHeight =
        resultCount * widget.resultHeight + _kResultsOverlayMargin;
    return Offset(0, -overlayHeight);
  }

  Widget _buildOverlay(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    final size = box.size;
    final count = _filtered.length;
    final totalHeight = count * widget.resultHeight + _kResultsOverlayMargin;
    final theme = MacosSearchFieldTheme.of(this.context);
    final highlight =
        theme.highlightColor ?? MacosTheme.of(this.context).primaryColor;

    return CompositedTransformFollower(
      link: _layerLink,
      showWhenUnlinked: false,
      offset: _overlayOffset(size, count),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: size.width,
          child: TextFieldTapRegion(
            child: MacosOverlayFilter(
              borderRadius: _kBorderRadius,
              color: theme.resultsBackgroundColor,
              child: SizedBox(
                height: totalHeight,
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: _overlayAbove,
                  padding: const EdgeInsets.all(6.0),
                  itemCount: _filtered.length,
                  itemExtent: widget.resultHeight,
                  itemBuilder: (context, index) {
                    final item = _filtered[index];
                    final selected = index == _highlightedIndex;
                    return _ResultRow(
                      height: widget.resultHeight,
                      highlighted: selected,
                      highlightColor: highlight,
                      onTap: () => _selectIndex(index),
                      onHover: () {
                        if (_highlightedIndex == index) return;
                        _highlightedIndex = index;
                        _refreshOverlay();
                      },
                      child:
                          item.child ??
                          Text(
                            item.searchKey,
                            overflow: TextOverflow.ellipsis,
                          ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MacosTextField(
        controller: _controller,
        focusNode: _focusNode,
        placeholder: widget.placeholder,
        style: widget.style,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        clearButtonMode: OverlayVisibilityMode.editing,
        prefix: const Padding(
          padding: EdgeInsets.symmetric(),
          child: MacosIcon(CupertinoIcons.search),
        ),
        onTap: () {
          if (!_isOverlayVisible) {
            _showOverlay();
          }
        },
        onChanged: _onQueryChanged,
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.height,
    required this.highlighted,
    required this.highlightColor,
    required this.onTap,
    required this.onHover,
    required this.child,
  });

  final double height;
  final bool highlighted;
  final Color highlightColor;
  final VoidCallback onTap;
  final VoidCallback onHover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = MacosTheme.brightnessOf(context);
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: highlighted ? highlightColor : const Color(0x00000000),
            borderRadius: _kBorderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          alignment: Alignment.centerLeft,
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13.0,
              color: highlighted
                  ? MacosColors.white
                  : brightness.resolve(MacosColors.black, MacosColors.white),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
