import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:timesheet/models/timetracker_item.dart';

class TimetrackerItemFieldControllers {
  late TextEditingController subject;
  late TextEditingController description;

  void initFrom(TimetrackerItem item) {
    subject = TextEditingController(text: _displaySubject(item));
    description = TextEditingController(text: item.description);
  }

  /// Syncs controller text from [item]. Safe to call from [State.didUpdateWidget]
  /// — defers writes when the framework is building so listeners do not
  /// [markNeedsBuild] mid-frame.
  void syncFrom(TimetrackerItem item, TimetrackerItem oldItem) {
    final nextSubject = _displaySubject(item);
    final nextDescription = item.description;
    final identityChanged =
        item.id != oldItem.id || item.itemIndex != oldItem.itemIndex;
    final subjectChanged =
        item.subject != oldItem.subject ||
        item.subjectName != oldItem.subjectName;

    void apply() {
      if (identityChanged) {
        _setTextIfChanged(subject, nextSubject);
        _setTextIfChanged(description, nextDescription);
        return;
      }

      if (subjectChanged) {
        _setTextIfChanged(subject, nextSubject);
      }
      if (item.description != description.text) {
        _setTextIfChanged(description, nextDescription);
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      apply();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    }
  }

  void dispose() {
    subject.dispose();
    description.dispose();
  }

  static void _setTextIfChanged(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.text = text;
  }

  static String _displaySubject(TimetrackerItem item) {
    return item.subjectName.isNotEmpty ? item.subjectName : item.subject;
  }
}
