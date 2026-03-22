import 'package:flutter/material.dart';
import '../../repository/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  LoginViewModel(this._repository);

  /// 기존 UI와 호환 위해 emailController 이름 유지
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  String? validateId(String raw) {
    final id = raw.trim();

    if (id.isEmpty) return '아이디를 입력해주세요.';
    if (id.length < 4 || id.length > 20) return '아이디는 4~20자여야 합니다.';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(id)) {
      return '아이디는 영문, 숫자, 점(.), 밑줄(_)만 사용할 수 있습니다.';
    }
    return null;
  }

  Future<bool> login() async {
    isLoading = true;
    notifyListeners();

    final id = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final idError = validateId(id);
      if (idError != null) {
        errorMessage = idError;
        return false;
      }

      await _repository.login(id, password);

      errorMessage = null;
      return true;
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');

      if (msg == '로그인 중 오류가 발생했습니다.' ||
          msg == '비밀번호가 일치하지 않습니다.' ||
          msg == '이메일 또는 비밀번호를 다시 확인해 주세요.' ||
          msg == '존재하지 않는 아이디입니다.') {
        final exists = await _repository.isIdAlreadyExists(id);

        if (!exists) {
          msg = '존재하지 않는 아이디입니다.';
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