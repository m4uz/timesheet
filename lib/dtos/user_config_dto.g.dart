// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserConfigDto _$UserConfigDtoFromJson(Map<String, dynamic> json) =>
    UserConfigDto(
      inputHistory: InputHistoryDto.fromJson(
        json['inputHistory'] as Map<String, dynamic>,
      ),
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserConfigDtoToJson(UserConfigDto instance) =>
    <String, dynamic>{
      'inputHistory': instance.inputHistory,
      'user': instance.user,
    };

InputHistoryDto _$InputHistoryDtoFromJson(Map<String, dynamic> json) =>
    InputHistoryDto(
      subjectList: (json['subjectList'] as List<dynamic>)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryList: (json['categoryList'] as List<dynamic>)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InputHistoryDtoToJson(InputHistoryDto instance) =>
    <String, dynamic>{
      'subjectList': instance.subjectList,
      'categoryList': instance.categoryList,
    };

UpdateUserOptionsRequestDto _$UpdateUserOptionsRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateUserOptionsRequestDto(
  subjectList: (json['subjectList'] as List<dynamic>)
      .map((e) => Subject.fromJson(e as Map<String, dynamic>))
      .toList(),
  categoryList: (json['categoryList'] as List<dynamic>)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UpdateUserOptionsRequestDtoToJson(
  UpdateUserOptionsRequestDto instance,
) => <String, dynamic>{
  'subjectList': instance.subjectList,
  'categoryList': instance.categoryList,
};

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  uuIdentity: json['uuIdentity'] as String,
  name: json['name'] as String,
  preferredLanguage: json['preferredLanguage'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'uuIdentity': instance.uuIdentity,
  'name': instance.name,
  'preferredLanguage': instance.preferredLanguage,
};
