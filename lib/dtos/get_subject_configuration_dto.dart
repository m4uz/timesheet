import 'package:json_annotation/json_annotation.dart';

part 'get_subject_configuration_dto.g.dart';

@JsonSerializable()
class GetSubjectConfigurationRequestDto {
  final String subject;

  GetSubjectConfigurationRequestDto({required this.subject});

  factory GetSubjectConfigurationRequestDto.fromJson(
    Map<String, dynamic> json,
  ) => _$GetSubjectConfigurationRequestDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetSubjectConfigurationRequestDtoToJson(this);
}

@JsonSerializable()
class GetSubjectConfigurationResponseDto {
  final String subjectUrl;
  final String name;
  final String? timesheetBCUri;
  final String? confirmerRoleId;
  final String? subjectId;
  final String? subjectAppUrl;
  final String? subjectUuObjectUri;
  final List<dynamic> supplierContractList;
  final Map<String, dynamic> uuAppErrorMap;

  GetSubjectConfigurationResponseDto({
    required this.subjectUrl,
    this.name = '',
    this.timesheetBCUri,
    this.confirmerRoleId,
    this.subjectId,
    this.subjectAppUrl,
    this.subjectUuObjectUri,
    this.supplierContractList = const [],
    this.uuAppErrorMap = const {},
  });

  factory GetSubjectConfigurationResponseDto.fromJson(
    Map<String, dynamic> json,
  ) => _$GetSubjectConfigurationResponseDtoFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GetSubjectConfigurationResponseDtoToJson(this);
}
