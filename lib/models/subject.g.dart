// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subject _$SubjectFromJson(Map<String, dynamic> json) => Subject(
  uri: json['uri'] as String,
  name: json['name'] as String? ?? '',
  unitName: json['unitName'] as String? ?? '',
  modificationTime: DateTime.parse(json['modificationTime'] as String),
);

Map<String, dynamic> _$SubjectToJson(Subject instance) => <String, dynamic>{
  'uri': instance.uri,
  'name': instance.name,
  'unitName': instance.unitName,
  'modificationTime': instance.modificationTime.toIso8601String(),
};
