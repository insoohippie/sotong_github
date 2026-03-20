import 'package:cloud_firestore/cloud_firestore.dart';
import '../data_source/auth_data_source.dart';
import '../data_source/auth_cache_data_source.dart';
import '../model/auth/signup_info.dart';

class AuthRepository {
  final AuthDataSource _remote;
  final AuthCacheDataSource _cache;

  AuthRepository(this._remote, this._cache);

  static const String _internalDomain = 'sotong.app';

  // =========================
  // Debug helpers
  // =========================
  void _log(String msg) {
    print('🧩 [AuthRepository] $msg');
  }

  void _logSessionSnapshot({String tag = ''}) {
    final t = tag.isEmpty ? '' : ' ($tag)';
    final uid = _cache.uid;
    final hasPlan = (uid == null) ? false : _cache.getHasPlanForUid(uid);

    _log(
      'SESSION$t => '
          'uid=$uid, '
          'loggedIn=${_cache.loggedIn}, '
          'loggedOutExplicit=${_cache.loggedOutExplicit}, '
          'hasPlan=$hasPlan',
    );
  }

  // =========================
  // Helpers
  // =========================
  String _normalizeId(String raw) => raw.trim().toLowerCase();

  String _toInternalEmail(String id) => '${_normalizeId(id)}@$_internalDomain';

  // =========================
  // Cache session getters (offline OK)
  // =========================
  String? get cachedUid => _cache.uid;
  bool get isCachedLoggedIn => _cache.loggedIn;
  bool get isCachedLoggedOutExplicit => _cache.loggedOutExplicit;

  bool get cachedHasPlan {
    final uid = cachedUid;
    if (uid == null) return false;
    return _cache.getHasPlanForUid(uid);
  }

  /// LogoSplash 라우팅 판단 (캐시만)
  bool get shouldAutoLogin {
    final result =
        isCachedLoggedIn && !isCachedLoggedOutExplicit && (cachedUid != null);
    _logSessionSnapshot(tag: 'shouldAutoLogin?=$result');
    return result;
  }

  // =========================
  // Remote current user (firebase)
  // =========================
  String? get currentUserId => _remote.currentUser?.uid;

  /// 내부 이메일
  String get currentUserEmail => _remote.currentUser?.email?.trim() ?? '';

  // =========================
  // Login (아이디 -> 내부 이메일 변환 -> auth -> cache)
  // =========================
  Future<void> login(String id, String password) async {
    _log('login() called: id=$id');
    _logSessionSnapshot(tag: 'before login');

    final internalEmail = _toInternalEmail(id);
    final cred = await _remote.loginWithAuth(internalEmail, password);
    final uid = cred.user?.uid;

    _log('loginWithAuth success: uid=$uid, email=${cred.user?.email}');
    if (uid == null) {
      _log('login failed: uid is null');
      throw Exception('로그인 실패(UID 없음)');
    }

    await _cache.setLoggedIn(uid: uid);

    _log('cache.setLoggedIn done');
    _logSessionSnapshot(tag: 'after login');
  }

  // =========================
  // Logout (remote -> cache)
  // =========================
  Future<void> logout() async {
    _log('logout() called');
    _logSessionSnapshot(tag: 'before logout');

    await _remote.signOut();
    _log('remote.signOut done');

    await _cache.setLoggedOutExplicit();
    _log('cache.setLoggedOutExplicit done');
    _logSessionSnapshot(tag: 'after logout');
  }

  // =========================
  // SignUp (아이디 -> 내부 이메일 생성 -> firestore + cache)
  // =========================
  Future<void> signUp(SignUpInfo info) async {
    _log('signUp() called: id=${info.id}');
    _logSessionSnapshot(tag: 'before signUp');

    final normalizedId = _normalizeId(info.id);
    final internalEmail = _toInternalEmail(normalizedId);

    info.id = normalizedId;
    info.email = internalEmail;

    final cred = await _remote.createUser(info.email, info.password);
    final user = cred.user;

    _log('createUser success: uid=${user?.uid}, email=${user?.email}');
    if (user == null) throw Exception('회원가입 실패(UID 없음)');

    info.userID = user.uid;

    final data = {
      ...info.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _remote.setUserDoc(user.uid, data, merge: true);
    _log('firestore setUserDoc done: users/${user.uid}');

    await _cache.setLoggedIn(uid: user.uid);
    await _cache.setHasPlanForUid(user.uid, false);

    _log('cache.setLoggedIn done (after signup)');
    _logSessionSnapshot(tag: 'after signUp');
  }

  // =========================
  // Plan flag
  // =========================
  Future<void> setHasPlan(bool value) async {
    final uid = cachedUid ?? currentUserId;
    if (uid == null) throw Exception('uid 없음');

    _log('setHasPlan($value) uid=$uid');
    await _cache.setHasPlanForUid(uid, value);
    _logSessionSnapshot(tag: 'after setHasPlan');
  }

  // =========================
  // Duplication check
  // =========================
  Future<bool> isIdAlreadyExists(String id) {
    final normalizedId = _normalizeId(id);
    _log('isIdAlreadyExists() called: id=$normalizedId');
    return _remote.isIdAlreadyExists(normalizedId);
  }

  /// 호환용 (기존 이름 유지)
  Future<bool> isEmailAlreadyExists(String id) {
    return isIdAlreadyExists(id);
  }

  // =========================
  // Etc existing methods
  // =========================
  Future<String> getUserName() async {
    final user = _remote.currentUser;
    _log('getUserName() called: remoteUser=${user?.uid}');
    if (user == null) return '회원';

    try {
      final doc = await _remote.getUserDoc(user.uid);
      final name = (doc.data()?['name'] as String?)?.trim();
      final result = (name == null || name.isEmpty) ? '회원' : name;
      _log('getUserName() result: $result');
      return result;
    } catch (e) {
      _log('getUserName() error: $e');
      return '회원';
    }
  }

  Future<String?> getBirthday() async {
    final uid = currentUserId;
    _log('getBirthday() called: uid=$uid');
    if (uid == null) return null;

    try {
      final doc = await _remote.getUserDoc(uid);
      final b = doc.data()?['birthday'] as String?;
      _log('getBirthday() result: $b');
      return b;
    } catch (e) {
      _log('getBirthday() error: $e');
      return null;
    }
  }

  Future<void> updateProfile({String? name, String? birthday}) async {
    final uid = currentUserId;
    _log('updateProfile() called: uid=$uid, name=$name, birthday=$birthday');
    if (uid == null) throw Exception('로그인이 필요합니다.');

    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (birthday != null) data['birthday'] = birthday;
    if (data.isEmpty) return;

    await _remote.setUserDoc(uid, data, merge: true);
    _log('updateProfile() firestore setUserDoc done');
  }

  Future<void> verifyCurrentPassword(String password) async {
    _log('verifyCurrentPassword() called');
    await _remote.verifyCurrentPassword(password);
    _log('verifyCurrentPassword() success');
  }

  Future<void> updatePasswordTo(String newPassword) async {
    _log('updatePasswordTo() called');
    await _remote.updatePasswordTo(newPassword);
    _log('updatePasswordTo() success');
  }

  String get nextRouteBySession {
    if (!shouldAutoLogin) return '/login';
    if (!cachedHasPlan) return '/plan_chat';
    return '/home_tab_navigator';
  }
}