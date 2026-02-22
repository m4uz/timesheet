// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  uuIdentity: json['uuIdentity'] as String,
  name: json['name'] as String,
  preferredLanguage: json['preferredLanguage'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'uuIdentity': instance.uuIdentity,
  'name': instance.name,
  'preferredLanguage': instance.preferredLanguage,
};
