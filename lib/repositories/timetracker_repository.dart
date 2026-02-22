import 'package:timesheet/dtos/create_timesheet_item_request_dto.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/services/timetracker_db_service.dart';
import 'package:timesheet/services/wtm_service.dart';

class TimetrackerRepository {
  final TimetrackerDBService _dbService;
  final IWTMService _wtmService;

  TimetrackerRepository({
    required TimetrackerDBService dbService,
    required IWTMService wtmService,
  }) : _dbService = dbService,
       _wtmService = wtmService;

  Future<Result<TimetrackerItem>> insert(TimetrackerItem item) async {
    return await _dbService.insert(item);
  }

  Future<Result<List<TimetrackerItem>>> insertBatch(
    List<TimetrackerItem> items,
  ) async {
    return await _dbService.insertBatch(items);
  }

  Future<Result<TimetrackerItem>> getById(int id) async {
    return await _dbService.getById(id);
  }

  Future<Result<List<TimetrackerItem>>> getAll() async {
    return await _dbService.getAll();
  }

  Future<Result<TimetrackerItem>> update(TimetrackerItem item) async {
    return await _dbService.update(item);
  }

  Future<Result<List<TimetrackerItem>>> updateBatch(
    List<TimetrackerItem> items,
  ) async {
    return await _dbService.updateBatch(items);
  }

  Future<Result<int>> deleteById(int id) async {
    return await _dbService.deleteById(id);
  }

  Future<Result<int>> deleteAll() async {
    return await _dbService.deleteAll();
  }

  Future<Result<TimetrackerItem>> saveToRemote(TimetrackerItem item) async {
    final request = CreateTimesheetItemRequestDto(
      datetimeFrom: _formatDateTimeWithTimezone(item.from),
      datetimeTo: _formatDateTimeWithTimezone(item.to),
      subject: item.subject,
      category: item.category,
      description: item.description,
    );

    final result = await _wtmService.createTimesheetItem(request);

    switch (result) {
      case OK(:final value):
        final updatedItem = item.copyWith(wtmId: value.id);
        return Result.ok(updatedItem);
      case Error(:final message):
        return Result.error(message);
    }
  }

  String _formatDateTimeWithTimezone(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    final offset = dateTime.timeZoneOffset;
    final offsetHours = offset.inHours.abs().toString().padLeft(2, '0');
    final offsetMinutes = (offset.inMinutes.abs() % 60).toString().padLeft(
      2,
      '0',
    );
    final offsetSign = offset.isNegative ? '-' : '+';

    return '$year-$month-${day}T$hour:$minute:$second$offsetSign$offsetHours:$offsetMinutes';
  }
}
