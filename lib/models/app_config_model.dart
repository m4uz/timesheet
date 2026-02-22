class AppConfigModel {
  final String logFile;
  final String logLevel;
  final String timetrackerDB;
  final String oidcIssuerUrl;
  final String oidcClientId;
  final String wtmBaseUrl;
  final String proxyHost;
  final int proxyPort;

  const AppConfigModel({
    required this.logFile,
    required this.logLevel,
    required this.timetrackerDB,
    required this.oidcIssuerUrl,
    required this.oidcClientId,
    required this.wtmBaseUrl,
    required this.proxyHost,
    required this.proxyPort,
  });

  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      logFile: (json['logFile'] as String?) ?? 'timesheet.log',
      logLevel: (json['logLevel'] as String?) ?? 'INFO',
      timetrackerDB: (json['timetrackerDB'] as String?) ?? 'timetracker.db',
      oidcIssuerUrl: (json['oidcIssuerUrl'] as String?) ?? '',
      oidcClientId: (json['oidcClientId'] as String?) ?? '',
      wtmBaseUrl: (json['wtmBaseUrl'] as String?) ?? '',
      proxyHost: (json['proxyHost'] as String?) ?? '',
      proxyPort: (json['proxyPort'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logFile': logFile,
      'logLevel': logLevel,
      'timetrackerDB': timetrackerDB,
      'oidcIssuerUrl': oidcIssuerUrl,
      'oidcClientId': oidcClientId,
      'wtmBaseUrl': wtmBaseUrl,
      'proxyHost': proxyHost,
      'proxyPort': proxyPort,
    };
  }

  AppConfigModel copyWith({
    String? logFile,
    String? logLevel,
    String? timetrackerDB,
    String? oidcIssuerUrl,
    String? oidcClientId,
    String? wtmBaseUrl,
    String? proxyHost,
    int? proxyPort,
  }) {
    return AppConfigModel(
      logFile: logFile ?? this.logFile,
      logLevel: logLevel ?? this.logLevel,
      timetrackerDB: timetrackerDB ?? this.timetrackerDB,
      oidcIssuerUrl: oidcIssuerUrl ?? this.oidcIssuerUrl,
      oidcClientId: oidcClientId ?? this.oidcClientId,
      wtmBaseUrl: wtmBaseUrl ?? this.wtmBaseUrl,
      proxyHost: proxyHost ?? this.proxyHost,
      proxyPort: proxyPort ?? this.proxyPort,
    );
  }
}
