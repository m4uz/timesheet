import 'package:json_annotation/json_annotation.dart';

part 'subject.g.dart';

@JsonSerializable()
class Subject {
  final String uri;
  final String name;
  final String unitName;
  final DateTime modificationTime;

  Subject({
    required this.uri,
    this.name = '',
    this.unitName = '',
    required this.modificationTime,
  });

  factory Subject.fromJson(Map<String, dynamic> json) =>
      _$SubjectFromJson(json);

  // Omit empty name/unitName so legacy subjects round-trip without those keys.
  Map<String, dynamic> toJson() {
    final json = _$SubjectToJson(this);
    if (name.isEmpty) json.remove('name');
    if (unitName.isEmpty) json.remove('unitName');
    return json;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject &&
        other.uri == uri &&
        other.name == name &&
        other.unitName == unitName &&
        other.modificationTime == modificationTime;
  }

  @override
  int get hashCode => Object.hash(uri, name, unitName, modificationTime);

  @override
  String toString() =>
      'Subject(uri: $uri, name: $name, unitName: $unitName, modificationTime: $modificationTime)';
}
