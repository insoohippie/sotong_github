import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data_source/auth_data_source.dart';
import '../model/signup_info.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  //로그인
  Future<bool> login(String email, String password) {
    return _dataSource.loginWithFirestore(email, password);
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
      ...info.toMap(),                 // 도메인 → Map
      'id': info.email,                // 이메일 인덱스 필드 유지 시
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
}
