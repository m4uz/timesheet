class Session {
  final String? accessToken;
  final String? userName;
  final String? email;
  final DateTime? expiresAt;

  const Session({this.accessToken, this.userName, this.email, this.expiresAt});

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
    String? email,
    DateTime? expiresAt,
  }) {
    return Session(
      accessToken: accessToken ?? this.accessToken,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  static const Session empty = Session();
}
