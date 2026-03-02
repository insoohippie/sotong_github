class SessionModel {
  final String? uid;
  final bool isLoggedIn;
  final bool hasPlan;
  final DateTime? logoutAt;
  final DateTime lastUpdatedAt;

  const SessionModel({
    required this.uid,
    required this.isLoggedIn,
    required this.hasPlan,
    required this.lastUpdatedAt,
    this.logoutAt,
  });

  factory SessionModel.initial() => SessionModel(
    uid: null,
    isLoggedIn: false,
    hasPlan: false,
    logoutAt: null,
    lastUpdatedAt: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'isLoggedIn': isLoggedIn,
    'hasPlan': hasPlan,
    'logoutAt': logoutAt?.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
  };

  factory SessionModel.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return SessionModel.initial();
    DateTime? _dt(String? s) => (s == null) ? null : DateTime.tryParse(s);
    return SessionModel(
      uid: (map['uid'] as String?)?.trim(),
      isLoggedIn: map['isLoggedIn'] == true,
      hasPlan: map['hasPlan'] == true,
      logoutAt: _dt(map['logoutAt'] as String?),
      lastUpdatedAt: _dt(map['lastUpdatedAt'] as String?) ?? DateTime.now(),
    );
  }

  SessionModel copyWith({
    String? uid,
    bool? isLoggedIn,
    bool? hasPlan,
    DateTime? logoutAt,
  }) {
    return SessionModel(
      uid: uid ?? this.uid,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      hasPlan: hasPlan ?? this.hasPlan,
      logoutAt: logoutAt ?? this.logoutAt,
      lastUpdatedAt: DateTime.now(),
    );
  }
}