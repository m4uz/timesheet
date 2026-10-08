// Adapted from Yaru's YaruEntrySegment / YaruNumericSegment
// (https://github.com/ubuntu/yaru.dart), MIT License.

import 'package:flutter/foundation.dart';

enum SegmentEventReturnAction {
  selectPreviousSegment,
  selectNextSegment,
  handled,
  ignored,
}

abstract interface class EntrySegment implements Listenable {
  String? get input;
  String get text;
  int get length;

  void onSelect(bool selected);
  SegmentEventReturnAction onInput(String input);
  SegmentEventReturnAction onUpArrowKey();
  SegmentEventReturnAction onDownArrowKey();
  SegmentEventReturnAction onBackspaceKey();
}

typedef NumericSegmentCallback =
    int? Function(String? input, int? value, int? oldValue)?;

/// Clamps segment values into [[min], [max]], falling back to [min] when null.
NumericSegmentCallback clampSegment(int min, int max) {
  return (_, value, oldValue) {
    if (value == null) return oldValue ?? min;
    if (value < min) return min;
    if (value > max) return max;
    return value;
  };
}

class NumericSegment extends ChangeNotifier implements EntrySegment {
  NumericSegment({
    required this.minLength,
    required this.maxLength,
    int? initialValue,
    required this.placeholderLetter,
    this.onValueChange,
    this.onInputCallback,
    this.onDownArrowKeyCallback,
    this.onUpArrowKeyCallback,
    this.arrowStep = 1,
    this.minValue = 0,
    this.maxValue,
  }) : assert(minLength > 0),
       assert(maxLength == null || maxLength >= minLength),
       _value = initialValue;

  NumericSegment.fixed({
    required int length,
    int? initialValue,
    required this.placeholderLetter,
    this.onValueChange,
    this.onInputCallback,
    this.onDownArrowKeyCallback,
    this.onUpArrowKeyCallback,
    this.arrowStep = 1,
    this.minValue = 0,
    this.maxValue,
  }) : assert(length > 0),
       _value = initialValue,
       minLength = length,
       maxLength = length;

  int? _value;
  int? get value => _value;
  set value(int? value) {
    final oldValue = _value;

    _value = onValueChange != null
        ? onValueChange!(_input, value, oldValue)
        : value;
    if (maxLength != null && _value != null && '$_value'.length > maxLength!) {
      _value = oldValue;
    }

    if (_value != oldValue) notifyListeners();
  }

  String? _input;
  @override
  String? get input => _input;
  set input(String? input) {
    _input = input;
  }

  final NumericSegmentCallback? onValueChange;
  final NumericSegmentCallback? onInputCallback;
  final NumericSegmentCallback? onUpArrowKeyCallback;
  final NumericSegmentCallback? onDownArrowKeyCallback;

  final String placeholderLetter;
  final int minLength;
  final int? maxLength;
  int arrowStep;
  final int minValue;
  final int? maxValue;

  bool _selected = false;
  bool _squashOnNextInput = false;

  @override
  String get text {
    final text = _formatValue();
    assert(text.length >= minLength);
    assert(maxLength == null || text.length <= maxLength!);
    return text;
  }

  String _formatValue() {
    if (value != null) {
      final stringValue = value!.abs().toString();
      final remainCharactersLength = minLength - stringValue.length;
      return '0' * remainCharactersLength + stringValue;
    }
    return placeholderLetter * minLength;
  }

  @override
  int get length => text.length;

  @override
  void onSelect(bool selected) {
    if (_selected == false && selected == true) {
      _squashOnNextInput = true;
    }
    _selected = selected;
  }

  @override
  SegmentEventReturnAction onInput(String userInput) {
    var action = SegmentEventReturnAction.handled;
    final oldValue = _value;
    int? candidateValue;

    if (_squashOnNextInput) {
      _value = null;
      _input = null;
      _squashOnNextInput = false;
    }

    var candidateInput = (_input ?? '') + userInput;
    final intCandidateInput = int.tryParse(candidateInput);

    if (intCandidateInput != null) {
      if (maxLength != null && candidateInput.length >= maxLength!) {
        candidateInput = candidateInput.length > maxLength!
            ? candidateInput.substring(0, maxLength!)
            : candidateInput;
        action = SegmentEventReturnAction.selectNextSegment;
      }
      _input = candidateInput;
      candidateValue = int.parse(candidateInput);
    }

    value = onInputCallback != null
        ? onInputCallback!(_input, candidateValue, oldValue)
        : candidateValue;

    if (action == SegmentEventReturnAction.selectNextSegment) {
      _input = null;
    }

    return action;
  }

  @override
  SegmentEventReturnAction onBackspaceKey() {
    if (value != null) {
      input = null;
      value = null;
      return SegmentEventReturnAction.handled;
    }
    return SegmentEventReturnAction.selectPreviousSegment;
  }

  @override
  SegmentEventReturnAction onUpArrowKey() {
    return _onArrowKey(arrowStep, minValue, onUpArrowKeyCallback);
  }

  @override
  SegmentEventReturnAction onDownArrowKey() {
    return _onArrowKey(-arrowStep, minValue, onDownArrowKeyCallback);
  }

  SegmentEventReturnAction _onArrowKey(
    int modifier,
    int defaultValue,
    NumericSegmentCallback? callback,
  ) {
    final oldValue = value;
    var candidateValue = value != null ? value! + modifier : defaultValue;

    final upper = maxValue;
    if (upper != null) {
      final range = upper - minValue + 1;
      candidateValue =
          ((candidateValue - minValue) % range + range) % range + minValue;
    }

    input = null;
    value = callback != null
        ? callback(_input, candidateValue, oldValue)
        : candidateValue;

    return SegmentEventReturnAction.handled;
  }
}

class SegmentedEntryController extends ChangeNotifier {
  SegmentedEntryController({required this.length, int initialIndex = 0})
    : assert(initialIndex >= 0 && initialIndex < length || length == 0),
      assert(length >= 0),
      _index = initialIndex;

  final int length;

  int _index;
  int get index => _index;
  set index(int index) {
    assert(index >= 0 && index < length);
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }

  bool maybeSelectPreviousSegment() {
    if (_index - 1 >= 0) {
      index--;
      return true;
    }
    return false;
  }

  bool maybeSelectNextSegment() {
    if (_index + 1 < length) {
      index++;
      return true;
    }
    return false;
  }

  void selectFirstSegment() => index = 0;

  void selectLastSegment() => index = length - 1;
}
