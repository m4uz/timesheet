import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: 'uuIdentity')
  final String uuIdentity;
  final String name;
  @JsonKey(name: 'preferredLanguage')
  final String? preferredLanguage;

  User({
    required this.uuIdentity,
    required this.name,
    this.preferredLanguage,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.uuIdentity == uuIdentity &&
        other.name == name &&
        other.preferredLanguage == preferredLanguage;
  }

  @override
  int get hashCode => Object.hash(uuIdentity, name, preferredLanguage);

  @override
  String toString() =>
      'User(uuIdentity: $uuIdentity, name: $name, preferredLanguage: $preferredLanguage)';
}

