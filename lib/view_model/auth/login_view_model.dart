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

    try {
      await _repository.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      errorMessage = null; // 성공 시 에러 초기화
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
