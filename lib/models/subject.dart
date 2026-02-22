import 'package:json_annotation/json_annotation.dart';

part 'subject.g.dart';

@JsonSerializable()
class Subject {
  final String uri;
  @JsonKey(name: 'modificationTime')
  final DateTime modificationTime;

  Subject({
    required this.uri,
    required this.modificationTime,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);

  Map<String, dynamic> toJson() => _$SubjectToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject &&
        other.uri == uri &&
        other.modificationTime == modificationTime;
  }

  @override
  int get hashCode => Object.hash(uri, modificationTime);

  @override
  String toString() => 'Subject(uri: $uri, modificationTime: $modificationTime)';
}

