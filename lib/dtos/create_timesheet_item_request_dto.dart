import 'package:json_annotation/json_annotation.dart';

part 'create_timesheet_item_request_dto.g.dart';

@JsonSerializable()
class CreateTimesheetItemRequestDto {
  final String datetimeFrom;
  final String datetimeTo;
  final String subject;
  final String category;
  final String description;

  CreateTimesheetItemRequestDto({
    required this.datetimeFrom,
    required this.datetimeTo,
    required this.subject,
    required this.category,
    required this.description,
  });

  factory CreateTimesheetItemRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTimesheetItemRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTimesheetItemRequestDtoToJson(this);
}
