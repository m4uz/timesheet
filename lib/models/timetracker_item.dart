import 'package:timesheet/models/timesheet_item.dart';

enum TimetrackerItemStatus {
  staged,
  saved,
  error;

  @override
  String toString() {
    switch (this) {
      case TimetrackerItemStatus.staged:
        return 'STA';
      case TimetrackerItemStatus.saved:
        return 'saved';
      case TimetrackerItemStatus.error:
        return 'error';
    }
  }

  static TimetrackerItemStatus fromString(String? value) {
    switch (value) {
      case 'staged':
        return TimetrackerItemStatus.staged;
      case 'saved':
        return TimetrackerItemStatus.saved;
      case 'error':
        return TimetrackerItemStatus.error;
      default:
        return TimetrackerItemStatus.staged;
    }
  }
}

class TimetrackerItem extends TimesheetItem {
  int id;
  int itemIndex;
  TimetrackerItemStatus status;
  String statusMsg;

  TimetrackerItem({
    super.wtmId,
    super.from,
    super.to,
    super.subject,
    super.category,
    super.description,
    this.id = -1,
    this.itemIndex = -1,
    this.status = TimetrackerItemStatus.staged,
    this.statusMsg = '',
  });

  @override
  TimetrackerItem copyWith({
    String? wtmId,
    DateTime? from,
    DateTime? to,
    String? subject,
    String? category,
    String? description,
    int? id,
    int? itemIndex,
    TimetrackerItemStatus? status,
    String? statusMsg,
  }) {
    return TimetrackerItem(
      wtmId: wtmId ?? this.wtmId,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      description: description ?? this.description,
      id: id ?? this.id,
      itemIndex: itemIndex ?? this.itemIndex,
      status: status ?? this.status,
      statusMsg: statusMsg ?? this.statusMsg,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'wtmId': wtmId,
      'itemIndex': itemIndex,
      'datetimeFrom': from.toIso8601String(),
      'datetimeTo': to.toIso8601String(),
      'subject': subject,
      'category': category,
      'description': description,
      'status': status.toString(),
      'statusMsg': statusMsg,
    };

    if (id != -1) {
      map['id'] = id;
    }

    return map;
  }

  factory TimetrackerItem.fromMap(Map<String, dynamic> map) {
    return TimetrackerItem(
      id: (map['id'] as int?) ?? -1,
      wtmId: (map['wtmId'] as String?) ?? '',
      itemIndex: (map['itemIndex'] as int?) ?? -1,
      from: _parseDateTime(map['datetimeFrom']),
      to: _parseDateTime(map['datetimeTo']),
      subject: (map['subject'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      status: TimetrackerItemStatus.fromString(map['status'] as String?),
      statusMsg: (map['statusMsg'] as String?) ?? '',
    );
  }

  @override
  String toString() {
    return 'TimetrackerItem('
        'id: $id, '
        'itemIndex: $itemIndex, '
        'wtmId: $wtmId, '
        'from: $from, '
        'to: $to, '
        'subject: $subject, '
        'category: $category, '
        'description: $description, '
        'status: $status, '
        'statusMsg: $statusMsg'
        ')';
  }

  TimesheetItem toTimesheetItem() {
    return TimesheetItem(
      wtmId: wtmId,
      from: from,
      to: to,
      subject: subject,
      category: category,
      description: description,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
