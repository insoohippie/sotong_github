import 'dart:io';

import '../data_source/auth_data_source.dart';
import '../model/signup_info.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  Future<bool> login(String email, String password) {
    return _dataSource.loginWithFirestore(email, password);
  }

  Future<void> signUp(SignUpInfo info, File? profileImage) {
    return _dataSource.signUp(info, profileImage: profileImage);
  }

  Future<bool> isEmailAlreadyExists(String email) {
    return _dataSource.isEmailAlreadyExists(email);
  }
}
