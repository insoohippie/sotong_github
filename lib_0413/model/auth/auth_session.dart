class AuthSession {
  final String? uid;
  final bool isLoggedIn;
  final bool didLogout;
  final bool hasPlan;

  const AuthSession({
    required this.uid,
    required this.isLoggedIn,
    required this.didLogout,
    required this.hasPlan,
  });

  factory AuthSession.empty() => const AuthSession(
    uid: null,
    isLoggedIn: false,
    didLogout: false,
    hasPlan: false,
  );

  AuthSession copyWith({
    String? uid,
    bool? isLoggedIn,
    bool? didLogout,
    bool? hasPlan,
  }) {
    return AuthSession(
      uid: uid ?? this.uid,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      didLogout: didLogout ?? this.didLogout,
      hasPlan: hasPlan ?? this.hasPlan,
    );
  }

  @override
  String toString() {
    return 'AuthSession(uid=$uid, isLoggedIn=$isLoggedIn, didLogout=$didLogout, hasPlan=$hasPlan)';
  }
}