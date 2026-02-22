import 'package:timesheet/dtos/list_worker_timesheet_items_request_dto.dart';
import 'package:timesheet/dtos/timesheet_item_dto.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timesheet_item.dart';
import 'package:timesheet/services/wtm_service.dart';

class TimesheetRepository {
  final IWTMService _service;

  TimesheetRepository({required IWTMService service}) : _service = service;

  Future<Result<List<TimesheetItem>>> listTimesheetItems(
    DateTime from,
    DateTime to,
  ) async {
    final request = ListWorkerTimesheetItemsRequestDto(
      datetimeFrom: from.toUtc().toIso8601String(),
      datetimeTo: to.toUtc().toIso8601String(),
    );

    final result = await _service.listWorkerTimesheetItemsByTime(request);

    switch (result) {
      case OK(:final value):
        final items = value.map(_dtoToDomain).toList();
        return Result.ok(items);
      case Error(:final message):
        return Result.error(message);
    }
  }

  TimesheetItem _dtoToDomain(TimesheetItemDto dto) {
    return TimesheetItem(
      wtmId: dto.id,
      from: DateTime.parse(dto.datetimeFrom),
      to: DateTime.parse(dto.datetimeTo),
      subject: dto.subject,
      category: dto.category,
      description: dto.description,
    );
  }
}
