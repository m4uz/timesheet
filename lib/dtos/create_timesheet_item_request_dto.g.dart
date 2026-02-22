// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_timesheet_item_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTimesheetItemRequestDto _$CreateTimesheetItemRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateTimesheetItemRequestDto(
  datetimeFrom: json['datetimeFrom'] as String,
  datetimeTo: json['datetimeTo'] as String,
  subject: json['subject'] as String,
  category: json['category'] as String,
  description: json['description'] as String,
);

Map<String, dynamic> _$CreateTimesheetItemRequestDtoToJson(
  CreateTimesheetItemRequestDto instance,
) => <String, dynamic>{
  'datetimeFrom': instance.datetimeFrom,
  'datetimeTo': instance.datetimeTo,
  'subject': instance.subject,
  'category': instance.category,
  'description': instance.description,
};
