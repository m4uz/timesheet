import 'package:flutter/material.dart';
import 'package:timesheet/models/timetracker_item.dart';

class TimetrackerItemFieldControllers {
  late TextEditingController subject;
  late TextEditingController description;

  void initFrom(
    TimetrackerItem item, {
    required String Function(String uri) subjectLabel,
  }) {
    subject = TextEditingController(text: subjectLabel(item.subject));
    description = TextEditingController(text: item.description);
  }

  void syncFrom(
    TimetrackerItem item,
    TimetrackerItem oldItem, {
    required String Function(String uri) subjectLabel,
  }) {
    if (item.id != oldItem.id || item.itemIndex != oldItem.itemIndex) {
      subject.text = subjectLabel(item.subject);
      description.text = item.description;
      return;
    }

    // Domain stores URI; field shows label — sync only when URI changes.
    if (item.subject != oldItem.subject) {
      subject.text = subjectLabel(item.subject);
    }
    if (item.description != description.text) {
      description.text = item.description;
    }
  }

  void dispose() {
    subject.dispose();
    description.dispose();
  }
}
