import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel(this._repository);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<User?> login() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = await _repository.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage = '존재하지 않는 이메일입니다.';
      } else if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 일치하지 않습니다.';
      } else {
        errorMessage = '로그인 실패: ${e.message}';
      }
    } catch (_) {
      errorMessage = '알 수 없는 오류가 발생했습니다.';
    }

    isLoading = false;
    notifyListeners();
    return null;
  }
}
