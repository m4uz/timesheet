// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timesheet_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimesheetItemDto _$TimesheetItemDtoFromJson(Map<String, dynamic> json) =>
    TimesheetItemDto(
      id: json['id'] as String,
      datetimeFrom: json['datetimeFrom'] as String,
      datetimeTo: json['datetimeTo'] as String,
      subject: json['subject'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      highRate: json['highRate'] as bool,
      supplierContract: json['supplierContract'] as String,
      data: json['data'] as Map<String, dynamic>,
      workerUuIdentity: json['workerUuIdentity'] as String,
      authorUuIdentity: json['authorUuIdentity'] as String,
      subjectOU: json['subjectOU'] as String,
      timesheetOU: json['timesheetOU'] as String,
      confirmerRole: json['confirmerRole'] as String,
      confirmerUuIdentity: json['confirmerUuIdentity'] as String,
      timesheetBC: json['timesheetBC'] as String,
      monthlyEvaluation: json['monthlyEvaluation'] as String,
      state: json['state'] as String,
      awid: json['awid'] as String,
      sys: SysDto.fromJson(json['sys'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TimesheetItemDtoToJson(TimesheetItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'datetimeFrom': instance.datetimeFrom,
      'datetimeTo': instance.datetimeTo,
      'subject': instance.subject,
      'category': instance.category,
      'description': instance.description,
      'highRate': instance.highRate,
      'supplierContract': instance.supplierContract,
      'data': instance.data,
      'workerUuIdentity': instance.workerUuIdentity,
      'authorUuIdentity': instance.authorUuIdentity,
      'subjectOU': instance.subjectOU,
      'timesheetOU': instance.timesheetOU,
      'confirmerRole': instance.confirmerRole,
      'confirmerUuIdentity': instance.confirmerUuIdentity,
      'timesheetBC': instance.timesheetBC,
      'monthlyEvaluation': instance.monthlyEvaluation,
      'state': instance.state,
      'awid': instance.awid,
      'sys': instance.sys,
    };

SysDto _$SysDtoFromJson(Map<String, dynamic> json) => SysDto(
  cts: json['cts'] as String,
  mts: json['mts'] as String,
  rev: (json['rev'] as num).toInt(),
);

Map<String, dynamic> _$SysDtoToJson(SysDto instance) => <String, dynamic>{
  'cts': instance.cts,
  'mts': instance.mts,
  'rev': instance.rev,
};
