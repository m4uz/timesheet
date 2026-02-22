import 'dart:io';
import 'package:logging/logging.dart';

class LogConfig {
  static IOSink? _sink;

  static void init(String logFilePath, Level logLevel) {
    _sink = File(logFilePath).openWrite(mode: FileMode.append);

    Logger.root.level = logLevel;
    Logger.root.onRecord.listen((record) {
      var msg =
          '[${record.time}] [${record.level.name}] [${record.loggerName}] ${_sanitize(record.message)}';
      if (record.stackTrace != null) {
        msg += ' ${record.stackTrace}';
      }
      print(msg);
      _sink?.writeln(msg);
    });
  }

  static String _sanitize(String message) {
    const fieldsToRedact = [
      'access_token',
      'id_token',
      'name',
      'given_name',
      'family_name',
      'email',
      'uuidentity',
    ];

    for (final field in fieldsToRedact) {
      if (message.contains('"$field":')) {
        message = message.replaceAll(
          RegExp('("$field":)(.+?)"'),
          '"$field":"REDACTED"',
        );
      }
    }

    return message;
  }
}
