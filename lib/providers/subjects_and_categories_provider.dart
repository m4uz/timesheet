import 'package:flutter/material.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/repositories/subjects_and_categories_repository.dart';

class SubjectsAndCategoriesProvider extends ChangeNotifier {
  final SubjectsAndCategoriesRepository _repository;

  bool _isLoading = false;
  List<Subject> _subjects = [];
  List<Category> _categories = [];
  String? _successMsg;
  String? _errorMsg;

  SubjectsAndCategoriesProvider({
    required this._repository,
  }) {
    loadSubjectsAndCategories();
  }

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get successMsg => _successMsg;
  String? get errorMsg => _errorMsg;

  Subject? findByUri(String uri) {
    if (uri.isEmpty) return null;
    for (final subject in _subjects) {
      if (subject.uri == uri) return subject;
    }
    return null;
  }

  String labelForUri(String uri) {
    if (uri.isEmpty) return '';
    final subject = findByUri(uri);
    if (subject == null) return uri;
    return subject.name.isNotEmpty ? subject.name : subject.uri;
  }

  bool isFetchableSubjectUri(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.startsWith('https://');
  }

  Future<Subject?> ensureSubjectForInput(String input) async {
    final trimmed = input.trim();
    if (!isFetchableSubjectUri(trimmed)) {
      return null;
    }

    final existingByInput = findByUri(trimmed);
    if (existingByInput != null) {
      return existingByInput;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;

    _isLoading = true;
    _errorMsg = null;
    notifyListeners();

    final result = await _repository.getSubjectConfiguration(trimmed);

    switch (result) {
      case OK(:final value):
        final existingBySubjectUrl = findByUri(value.uri);
        if (existingBySubjectUrl == null) {
          _subjects = [value, ..._subjects];
        }
        _isLoading = false;
        return existingBySubjectUrl ?? value;
      case Error(:final message):
        _errorMsg = message;
        _isLoading = false;
        notifyListeners();
        return null;
    }
  }

  Future<void> loadSubjectsAndCategories() async {
    _isLoading = true;
    _successMsg = null;
    _errorMsg = null;
    notifyListeners();

    final result = await _repository.loadSubjectsAndCategories();

    switch (result) {
      case OK(:final value):
        _subjects = value.subjects;
        _categories = value.categories;
      case Error():
        _subjects = [];
        _categories = [];
        _errorMsg = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSubjectsAndCategories() async {
    _isLoading = true;
    _successMsg = null;
    _errorMsg = null;
    notifyListeners();

    final result = await _repository.updateSubjectsAndCategories(
      subjects: _subjects,
      categories: _categories,
    );

    switch (result) {
      case OK(:final value):
        _subjects = value.subjects;
        _categories = value.categories;
        _successMsg = "Options saved";
      case Error():
        _errorMsg = result.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSubject(Subject subject) async {
    _subjects = _subjects.where((s) => s.uri != subject.uri).toList();
    notifyListeners();
  }

  Future<void> deleteCategory(Category category) async {
    _categories = _categories.where((c) => c.name != category.name).toList();
    notifyListeners();
  }

  void clearSuccessMsg() {
    _successMsg = null;
  }

  void clearErrorMsg() {
    _errorMsg = null;
  }
}
