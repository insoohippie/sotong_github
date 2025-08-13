import 'dart:io';

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

  //회원가입
  Future<void> signUp(SignUpInfo info) {
    return _dataSource.signUp(info);
  }

  /// Firestore(users/{uid})의 name 우선, 없으면 '회원'
  Future<String> getUserName() async {
    final user = _dataSource.currentUser;
    if (user == null) return '회원';

    try {
      final doc = await _dataSource.getUserDoc(user.uid);
      final name = (doc.data()?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return name;
      return '회원';
    } catch (_) {
      return '회원';
    }
  }
}
