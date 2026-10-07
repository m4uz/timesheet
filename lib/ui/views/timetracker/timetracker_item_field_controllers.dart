import 'package:flutter/material.dart';
import 'package:timesheet/models/timetracker_item.dart';

class TimetrackerItemFieldControllers {
  late TextEditingController subject;
  late TextEditingController description;

  void initFrom(TimetrackerItem item) {
    subject = TextEditingController(text: _displaySubject(item));
    description = TextEditingController(text: item.description);
  }

  void syncFrom(TimetrackerItem item, TimetrackerItem oldItem) {
    if (item.id != oldItem.id || item.itemIndex != oldItem.itemIndex) {
      subject.text = _displaySubject(item);
      description.text = item.description;
      return;
    }

    if (item.subject != oldItem.subject ||
        item.subjectName != oldItem.subjectName) {
      subject.text = _displaySubject(item);
    }
    if (item.description != description.text) {
      description.text = item.description;
    }
  }

  void dispose() {
    subject.dispose();
    description.dispose();
  }

  static String _displaySubject(TimetrackerItem item) {
    return item.subjectName.isNotEmpty ? item.subjectName : item.subject;
  }
}
