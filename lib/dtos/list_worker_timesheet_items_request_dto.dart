import 'package:json_annotation/json_annotation.dart';

part 'list_worker_timesheet_items_request_dto.g.dart';

@JsonSerializable()
class ListWorkerTimesheetItemsRequestDto {
  final String datetimeFrom;
  final String datetimeTo;

  ListWorkerTimesheetItemsRequestDto({
    required this.datetimeFrom,
    required this.datetimeTo,
  });

  factory ListWorkerTimesheetItemsRequestDto.fromJson(
    Map<String, dynamic> json,
  ) => _$ListWorkerTimesheetItemsRequestDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$ListWorkerTimesheetItemsRequestDtoToJson(this);
}
