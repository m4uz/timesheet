import 'package:flutter/material.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/repositories/timetracker_repository.dart';

class TimetrackerProvider extends ChangeNotifier {
  final TimetrackerRepository _repository;

  bool _isLoading = false;
  final Set<String> _savingKeys = {};
  List<TimetrackerItem> _items = [];
  String? _successMsg;
  String? _errorMsg;

  TimetrackerProvider({required TimetrackerRepository repository})
    : _repository = repository {
    loadItems();
  }

  List<TimetrackerItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get successMsg => _successMsg;
  String? get errorMsg => _errorMsg;
  bool isSavingItem(TimetrackerItem item) => _savingKeys.contains(_itemKey(item));

  int get itemCount => _items.length;

  Duration get totalDuration {
    Duration total = Duration.zero;
    for (final item in _items) {
      total += item.to.difference(item.from);
    }
    return total;
  }

  Future<void> loadItems() async {
    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    final result = await _repository.getAll();

    switch (result) {
      case OK():
        _items = List.from(result.value)
          ..sort((a, b) => a.itemIndex.compareTo(b.itemIndex));
      case Error():
        _items = [];
        _errorMsg = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem() async {
    _errorMsg = null;

    final fromTime = _items.isEmpty ? _round(DateTime.now()) : _items.last.to;
    final toTime = fromTime.add(Duration(minutes: 15)); // TODO configurable
    final newItem = TimetrackerItem(
      from: fromTime,
      to: toTime,
      subject: '',
      description: '',
      itemIndex: _items.length,
    );

    final result = await _repository.insert(newItem);

    switch (result) {
      case OK():
        _items.add(result.value);
      case Error():
        _errorMsg = result.message;
    }

    notifyListeners();
  }

  Future<void> updateItem(TimetrackerItem item) async {
    _errorMsg = null;

    final result = await _repository.update(item);

    switch (result) {
      case OK():
        _items[item.itemIndex] = result.value;
      case Error():
        _errorMsg = result.message;
    }

    notifyListeners();
  }

  Future<void> deleteItem(TimetrackerItem item) async {
    _errorMsg = null;

    final result = await _repository.deleteById(item.id);

    switch (result) {
      case OK():
        _items.remove(item);
        // Update itemIndex for items that came after the deleted one
        final itemsToUpdate = <TimetrackerItem>[];
        for (int i = item.itemIndex; i < _items.length; i++) {
          _items[i].itemIndex = i;
          itemsToUpdate.add(_items[i]);
        }

        if (itemsToUpdate.isNotEmpty) {
          final updateResult = await _repository.updateBatch(itemsToUpdate);
          switch (updateResult) {
            case OK():
              // Items already updated in _items list above
              break;
            case Error(:final message):
              _errorMsg = message;
          }
        }
      case Error():
        _errorMsg = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteAll() async {
    _errorMsg = null;

    final result = await _repository.deleteAll();

    switch (result) {
      case OK():
        _items.clear();
      case Error():
        _errorMsg = result.message;
    }

    notifyListeners();
  }

  Future<void> reorderItems(int oldIndex, int newIndex) async {
    _errorMsg = null;
    notifyListeners();

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // Remove the item from oldIndex and insert it at newIndex
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    // Update itemIndex for all affected items
    final startIndex = oldIndex < newIndex ? oldIndex : newIndex;
    final endIndex = oldIndex < newIndex ? newIndex : oldIndex;
    final itemsToUpdate = <TimetrackerItem>[];

    for (int i = startIndex; i <= endIndex; i++) {
      _items[i] = _items[i].copyWith(itemIndex: i);
      itemsToUpdate.add(_items[i]);
    }

    // Update all affected items in the repository
    for (final itemToUpdate in itemsToUpdate) {
      final result = await _repository.update(itemToUpdate);
      if (result case Error(:final message)) {
        _errorMsg = message;
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    notifyListeners();
  }

  Future<void> saveToWTM() async {
    _isLoading = true;
    _errorMsg = null;
    _successMsg = null;
    notifyListeners();

    final itemsToSave = _items
        .where((item) => item.status != TimetrackerItemStatus.saved)
        .toList();

    if (itemsToSave.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    for (final item in itemsToSave) {
      final itemKey = _itemKey(item);
      _savingKeys.add(itemKey);
      notifyListeners();
      final result = await _repository.saveToRemote(item);
      _savingKeys.remove(itemKey);

      switch (result) {
        case OK(:final value):
          updateItem(value.copyWith(status: TimetrackerItemStatus.saved));
        case Error(:final message):
          updateItem(
            item.copyWith(
              status: TimetrackerItemStatus.error,
              statusMsg: message,
            ),
          );
          _errorMsg = message;
          _isLoading = false;
          notifyListeners();
          return;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSuccessMsg() {
    _successMsg = null;
  }

  void clearErrorMsg() {
    _errorMsg = null;
  }

  String _itemKey(TimetrackerItem item) => '${item.id}:${item.itemIndex}';

  DateTime _round(DateTime time) {
    final minutes = time.minute;
    final roundedMinutes = (minutes ~/ 15) * 15;

    return DateTime(time.year, time.month, time.day, time.hour, roundedMinutes);
  }
}
