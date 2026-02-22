import 'package:flutter/material.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/repositories/timesheet_repository.dart';

class TimesheetProvider extends ChangeNotifier {
  final TimesheetRepository _repository;

  bool _isLoading = false;
  List<TimesheetItem> _items = [];
  String? _errorMsg;
  DateTime _fromDate;
  DateTime _toDate;
  DateTime? _lastLoadedFromDate;
  DateTime? _lastLoadedToDate;
  String _filter = '';

  TimesheetProvider({required TimesheetRepository repository})
    : _repository = repository,
      _fromDate = DateTime.now(),
      _toDate = DateTime.now();

  List<TimesheetItem> get items {
    final normalizedFilter = _filter.trim().toLowerCase();
    if (normalizedFilter.isEmpty) {
      return List.unmodifiable(_items);
    }

    return List.unmodifiable(
      _items.where((item) {
        return item.subject.trim().toLowerCase().contains(normalizedFilter) ||
            item.category.trim().toLowerCase().contains(normalizedFilter) ||
            item.description.trim().toLowerCase().contains(normalizedFilter);
      }),
    );
  }

  bool get isLoading => _isLoading;
  String? get errorMsg => _errorMsg;
  DateTime get fromDate => _fromDate;
  DateTime get toDate => _toDate;
  String get filter => _filter;
  int get itemCount => items.length;

  Duration get totalDuration {
    Duration total = Duration.zero;
    for (final item in items) {
      total += item.to.difference(item.from);
    }
    return total;
  }

  void setFilter(String value) {
    _filter = value;
    notifyListeners();
  }

  void setFromDate(DateTime date) {
    _fromDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setToDate(DateTime date) {
    _toDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> loadTimesheetItems({bool forceReload = false}) async {
    if (!forceReload &&
        _lastLoadedFromDate != null &&
        _lastLoadedToDate != null &&
        _lastLoadedFromDate == _fromDate &&
        _lastLoadedToDate == _toDate) {
      return;
    }

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    final normalizedFrom = DateTime(
      _fromDate.year,
      _fromDate.month,
      _fromDate.day - 1,
      23,
      0,
      0,
      0,
    ).toUtc();

    final normalizedTo = DateTime(
      _toDate.year,
      _toDate.month,
      _toDate.day,
      23,
      0,
      0,
      999,
    ).toUtc();

    final result = await _repository.listTimesheetItems(
      normalizedFrom,
      normalizedTo,
    );

    switch (result) {
      case OK():
        _items = List.from(result.value);
        _lastLoadedFromDate = _fromDate;
        _lastLoadedToDate = _toDate;
      case Error():
        _items = [];
        _errorMsg = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearErrorMsg() {
    _errorMsg = null;
    notifyListeners();
  }
}
