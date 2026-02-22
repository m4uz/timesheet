// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_worker_timesheet_items_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListWorkerTimesheetItemsRequestDto _$ListWorkerTimesheetItemsRequestDtoFromJson(
  Map<String, dynamic> json,
) => ListWorkerTimesheetItemsRequestDto(
  datetimeFrom: json['datetimeFrom'] as String,
  datetimeTo: json['datetimeTo'] as String,
);

Map<String, dynamic> _$ListWorkerTimesheetItemsRequestDtoToJson(
  ListWorkerTimesheetItemsRequestDto instance,
) => <String, dynamic>{
  'datetimeFrom': instance.datetimeFrom,
  'datetimeTo': instance.datetimeTo,
};
