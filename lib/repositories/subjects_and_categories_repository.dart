import 'package:timesheet/dtos/user_config_dto.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/services/wtm_service.dart';

class SubjectsAndCategoriesRepository {
  final IWTMService _service;

  SubjectsAndCategoriesRepository({required IWTMService service})
    : _service = service;

  Future<Result<({List<Subject> subjects, List<Category> categories})>>
  loadSubjectsAndCategories() async {
    final result = await _service.loadConfigAndUserInfo();

    switch (result) {
      case OK(:final value):
        final sortedSubjects = List<Subject>.from(value.subjects)
          ..sort((a, b) => b.modificationTime.compareTo(a.modificationTime));
        final sortedCategories = List<Category>.from(value.categories)
          ..sort((a, b) => b.modificationTime.compareTo(a.modificationTime));
        return Result.ok((
          subjects: sortedSubjects,
          categories: sortedCategories,
        ));
      case Error(:final message):
        return Result.error(message);
    }
  }

  Future<Result<({List<Subject> subjects, List<Category> categories})>>
  updateSubjectsAndCategories({
    required List<Subject> subjects,
    required List<Category> categories,
  }) async {
    final request = UpdateUserOptionsRequestDto(
      subjectList: subjects,
      categoryList: categories,
    );

    final result = await _service.updateUserOptions(request);

    switch (result) {
      case OK(:final value):
        final sortedSubjects = List<Subject>.from(value.subjects)
          ..sort((a, b) => b.modificationTime.compareTo(a.modificationTime));
        final sortedCategories = List<Category>.from(value.categories)
          ..sort((a, b) => b.modificationTime.compareTo(a.modificationTime));
        return Result.ok((
          subjects: sortedSubjects,
          categories: sortedCategories,
        ));
      case Error(:final message):
        return Result.error(message);
    }
  }
}
