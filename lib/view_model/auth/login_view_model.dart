import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel(this._repository);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login() async {
    isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // 1) Auth 기반 로그인 시도
      await _repository.login(email, password);

      errorMessage = null;
      return true;

    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');

      // 2) FirebaseAuth가 invalid-credential을 줬을 때 분기 처리
      //    (이메일 없음 vs 비밀번호 틀림을 구분)
      if (msg == '로그인 중 오류가 발생했습니다.' ||
          msg == '비밀번호가 일치하지 않습니다.' ||
          msg == '이메일 또는 비밀번호를 다시 확인해 주세요.') {

        // Firestore에서 이메일 존재 여부 직접 확인
        final exists = await _repository.isEmailAlreadyExists(email);

        if (!exists) {
          msg = '존재하지 않는 이메일입니다.';
        } else {
          msg = '비밀번호가 일치하지 않습니다.';
        }
      }

      errorMessage = msg;
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}