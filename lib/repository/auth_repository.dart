import 'package:cloud_firestore/cloud_firestore.dart';

import '../data_source/auth_data_source.dart';
import '../model/auth/signup_info.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  //로그인
  // Future<bool> login(String email, String password) {
  //   return _dataSource.loginWithFirestore(email, password);
  // }
  Future<void> login(String email, String password) async {
    await _dataSource.loginWithAuth(email, password);
  }

  //이메일 중복 확인
  Future<bool> isEmailAlreadyExists(String email) {
    return _dataSource.isEmailAlreadyExists(email);
  }

  // 회원가입: 도메인 → Map 변환 + 두 단계 호출(Auth 생성 -> Firestore 저장)
  Future<void> signUp(SignUpInfo info) async {
    final cred = await _dataSource.createUser(info.email, info.password);
    final user = cred.user;
    if (user == null) {
      throw Exception('회원가입 실패(UID 없음)');
    }

    info.userID = user.uid;

    final data = {
      ...info.toMap(), // 도메인 → Map
      'id': info.email, // 이메일 인덱스 필드 유지 시
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _dataSource.setUserDoc(user.uid, data, merge: true);
  }

  /// Firestore(users/{uid})의 name 우선, 없으면 '회원'
  Future<String> getUserName() async {
    final user = _dataSource.currentUser;
    if (user == null) return '회원';
    try {
      final doc = await _dataSource.getUserDoc(user.uid);
      final name = (doc.data()?['name'] as String?)?.trim();
      return (name == null || name.isEmpty) ? '회원' : name;
    } catch (_) {
      return '회원';
    }
  }

  /// 현재 로그인 UID (필요시)
  String? get currentUserId => _dataSource.currentUser?.uid;

  /// 현재 로그인 사용자 이메일 (설정 등 표시용)
  String get currentUserEmail => _dataSource.currentUser?.email?.trim() ?? '';

  /// Firestore에서 생년월일 조회
  Future<String?> getBirthday() async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final doc = await _dataSource.getUserDoc(uid);
      return doc.data()?['birthday'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// 프로필 수정 (이름, 생년월일) - Firestore
  Future<void> updateProfile({String? name, String? birthday}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (birthday != null) data['birthday'] = birthday;
    if (data.isEmpty) return;
    await _dataSource.setUserDoc(uid, data, merge: true);
  }

  /// 현재 비밀번호 확인 (재인증)
  Future<void> verifyCurrentPassword(String password) async {
    await _dataSource.verifyCurrentPassword(password);
  }

  /// 비밀번호 변경 (verifyCurrentPassword 성공 직후에만 호출)
  Future<void> updatePasswordTo(String newPassword) async {
    await _dataSource.updatePasswordTo(newPassword);
  }

  /// 로그아웃
  Future<void> logout() async {
    await _dataSource.signOut();
  }
}
