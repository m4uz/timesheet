class TimesheetItem {
  String wtmId;
  DateTime from;
  DateTime to;
  String subject;
  String subjectName;
  String category;
  String description;

  TimesheetItem({
    this.wtmId = '',
    DateTime? from,
    DateTime? to,
    this.subject = '',
    this.subjectName = '',
    this.category = '',
    this.description = '',
  }) : from = from ?? DateTime.fromMillisecondsSinceEpoch(0),
       to = to ?? DateTime.fromMillisecondsSinceEpoch(0);

  TimesheetItem copyWith({
    String? wtmId,
    DateTime? from,
    DateTime? to,
    String? subject,
    String? subjectName,
    String? category,
    String? description,
  }) {
    return TimesheetItem(
      wtmId: wtmId ?? this.wtmId,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      subjectName: subjectName ?? this.subjectName,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimesheetItem &&
        other.wtmId == wtmId &&
        other.from == from &&
        other.to == to &&
        other.subject == subject &&
        other.subjectName == subjectName &&
        other.category == category &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      wtmId,
      from,
      to,
      subject,
      subjectName,
      category,
      description,
    );
  }

  @override
  String toString() {
    return 'TimesheetItem(wtmId: $wtmId, from: $from, to: $to, subject: $subject, subjectName: $subjectName, category: $category, description: $description)';
  }
}
