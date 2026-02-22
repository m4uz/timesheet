import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String name;
  @JsonKey(name: 'modificationTime')
  final DateTime modificationTime;

  Category({required this.name, required this.modificationTime});

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.name == name &&
        other.modificationTime == modificationTime;
  }

  @override
  int get hashCode => Object.hash(name, modificationTime);

  @override
  String toString() =>
      'Category(name: $name, modificationTime: $modificationTime)';
}
