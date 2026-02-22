import 'package:flutter/material.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/repositories/subjects_and_categories_repository.dart';

class SubjectsCategoriesProvider extends ChangeNotifier {
  final SubjectsAndCategoriesRepository _repository;

  bool _isLoading = false;
  List<Subject> _subjects = [];
  List<Category> _categories = [];
  String? _successMsg;
  String? _errorMsg;

  SubjectsCategoriesProvider({
    required SubjectsAndCategoriesRepository repository,
  }) : _repository = repository {
    loadSubjectsAndCategories();
  }

  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Category> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get successMsg => _successMsg;
  String? get errorMsg => _errorMsg;

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
