import 'package:json_annotation/json_annotation.dart';

part 'timesheet_item_dto.g.dart';

@JsonSerializable()
class TimesheetItemDto {
  final String id;
  final String datetimeFrom;
  final String datetimeTo;
  final String subject;
  final String category;
  final String description;
  final bool highRate;
  final String supplierContract;
  final Map<String, dynamic> data;
  final String workerUuIdentity;
  final String authorUuIdentity;
  final String subjectOU;
  final String timesheetOU;
  final String confirmerRole;
  final String confirmerUuIdentity;
  final String timesheetBC;
  final String monthlyEvaluation;
  final String state;
  final String awid;
  final SysDto sys;

  TimesheetItemDto({
    required this.id,
    required this.datetimeFrom,
    required this.datetimeTo,
    required this.subject,
    required this.category,
    required this.description,
    required this.highRate,
    required this.supplierContract,
    required this.data,
    required this.workerUuIdentity,
    required this.authorUuIdentity,
    required this.subjectOU,
    required this.timesheetOU,
    required this.confirmerRole,
    required this.confirmerUuIdentity,
    required this.timesheetBC,
    required this.monthlyEvaluation,
    required this.state,
    required this.awid,
    required this.sys,
  });

  factory TimesheetItemDto.fromJson(Map<String, dynamic> json) => _$TimesheetItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TimesheetItemDtoToJson(this);
}

@JsonSerializable()
class SysDto {
  final String cts;
  final String mts;
  final int rev;

  SysDto({required this.cts, required this.mts, required this.rev});

  factory SysDto.fromJson(Map<String, dynamic> json) => _$SysDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SysDtoToJson(this);
}
