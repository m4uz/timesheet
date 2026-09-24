// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_subject_configuration_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetSubjectConfigurationRequestDto _$GetSubjectConfigurationRequestDtoFromJson(
  Map<String, dynamic> json,
) => GetSubjectConfigurationRequestDto(subject: json['subject'] as String);

Map<String, dynamic> _$GetSubjectConfigurationRequestDtoToJson(
  GetSubjectConfigurationRequestDto instance,
) => <String, dynamic>{'subject': instance.subject};

GetSubjectConfigurationResponseDto _$GetSubjectConfigurationResponseDtoFromJson(
  Map<String, dynamic> json,
) => GetSubjectConfigurationResponseDto(
  subjectUrl: json['subjectUrl'] as String,
  name: json['name'] as String? ?? '',
  timesheetBCUri: json['timesheetBCUri'] as String?,
  confirmerRoleId: json['confirmerRoleId'] as String?,
  subjectId: json['subjectId'] as String?,
  subjectAppUrl: json['subjectAppUrl'] as String?,
  subjectUuObjectUri: json['subjectUuObjectUri'] as String?,
  supplierContractList: json['supplierContractList'] as List<dynamic>? ?? const [],
  uuAppErrorMap:
      json['uuAppErrorMap'] as Map<String, dynamic>? ?? const <String, dynamic>{},
);

Map<String, dynamic> _$GetSubjectConfigurationResponseDtoToJson(
  GetSubjectConfigurationResponseDto instance,
) => <String, dynamic>{
  'subjectUrl': instance.subjectUrl,
  'name': instance.name,
  'timesheetBCUri': instance.timesheetBCUri,
  'confirmerRoleId': instance.confirmerRoleId,
  'subjectId': instance.subjectId,
  'subjectAppUrl': instance.subjectAppUrl,
  'subjectUuObjectUri': instance.subjectUuObjectUri,
  'supplierContractList': instance.supplierContractList,
  'uuAppErrorMap': instance.uuAppErrorMap,
};
