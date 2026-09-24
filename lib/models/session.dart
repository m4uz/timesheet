class Session {
  final String? accessToken;
  final String? userName;
  final String? uuidentity;
  final DateTime? expiresAt;

  const Session({
    this.accessToken,
    this.userName,
    this.uuidentity,
    this.expiresAt,
  });

  bool get isValid =>
      accessToken != null &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  bool get isEmpty => accessToken == null;

  bool expiresWithin(Duration duration) {
    if (expiresAt == null) return false;
    final timeUntilExpiry = expiresAt!.difference(DateTime.now());
    return timeUntilExpiry <= duration && timeUntilExpiry > Duration.zero;
  }

  Duration? get timeUntilExpiry {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Session copyWith({
    String? accessToken,
    String? userName,
    String? uuidentity,
    DateTime? expiresAt,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      userName: userName ?? this.userName,
      uuidentity: uuidentity ?? this.uuidentity,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static const Session empty = Session();
}
