import 'package:json_annotation/json_annotation.dart';
import 'package:timesheet/models/category.dart';
import 'package:timesheet/models/subject.dart';
import 'package:timesheet/models/user.dart';

part 'user_config_dto.g.dart';

@JsonSerializable()
class UserConfigDto {
  @JsonKey(name: 'inputHistory')
  final InputHistoryDto inputHistory;
  final UserDto user;

  UserConfigDto({required this.inputHistory, required this.user});

  factory UserConfigDto.fromJson(Map<String, dynamic> json) =>
      _$UserConfigDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserConfigDtoToJson(this);

  List<Subject> get subjects => inputHistory.subjectList;
  List<Category> get categories => inputHistory.categoryList;
}

@JsonSerializable()
class InputHistoryDto {
  @JsonKey(name: 'subjectList')
  final List<Subject> subjectList;
  @JsonKey(name: 'categoryList')
  final List<Category> categoryList;

  InputHistoryDto({required this.subjectList, required this.categoryList});

  factory InputHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$InputHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$InputHistoryDtoToJson(this);
}

@JsonSerializable()
class UpdateUserOptionsRequestDto {
  @JsonKey(name: 'subjectList')
  final List<Subject> subjectList;
  @JsonKey(name: 'categoryList')
  final List<Category> categoryList;

  UpdateUserOptionsRequestDto({
    required this.subjectList,
    required this.categoryList,
  });

  factory UpdateUserOptionsRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserOptionsRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserOptionsRequestDtoToJson(this);
}

@JsonSerializable()
class UserDto {
  @JsonKey(name: 'uuIdentity')
  final String uuIdentity;
  final String name;
  @JsonKey(name: 'preferredLanguage')
  final String? preferredLanguage;

  UserDto({
    required this.uuIdentity,
    required this.name,
    this.preferredLanguage,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);

  User toUser() {
    return User(
      uuIdentity: uuIdentity,
      name: name,
      preferredLanguage: preferredLanguage,
    );
  }
}
