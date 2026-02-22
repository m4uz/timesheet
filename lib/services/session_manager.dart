import 'package:flutter/foundation.dart';
import 'package:timesheet/models/session.dart';

class SessionManager extends ValueNotifier<Session> {
  SessionManager() : super(Session.empty);

  void updateSession(Session session) {
    value = session;
  }

  void clearSession() {
    value = Session.empty;
  }

  String? get accessToken => value.accessToken;
  DateTime? get expiresAt => value.expiresAt;
  String? get userName => value.userName;
  String? get email => value.email;
  bool get isValid => value.isValid;
  bool get isEmpty => value.isEmpty;
}
