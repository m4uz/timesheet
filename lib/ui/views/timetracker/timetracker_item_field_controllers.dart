import 'package:flutter/material.dart';
import 'package:timesheet/models/timetracker_item.dart';

class TimetrackerItemFieldControllers {
  late TextEditingController subject;
  late TextEditingController description;

  void initFrom(TimetrackerItem item) {
    subject = TextEditingController(text: item.subject);
    description = TextEditingController(text: item.description);
  }

  void syncFrom(TimetrackerItem item, TimetrackerItem oldItem) {
    if (item.id != oldItem.id || item.itemIndex != oldItem.itemIndex) {
      subject.text = item.subject;
      description.text = item.description;
      return;
    }

    if (item.subject != subject.text) {
      subject.text = item.subject;
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
