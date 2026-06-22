import 'package:flutter/material.dart';

import '../../model/auth/signup_info.dart';
import '../../repository/auth_repository.dart';

enum SignupStep { email, password, userInfo }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  SignupViewModel(this._repo);

  SignupStep currentStep = SignupStep.email;

  /// 실제로는 아이디 입력
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final nicknameController = TextEditingController();

  SignUpInfo? signUpInfo;

  String? emailError;
  bool isLoading = false;
  bool isEmailChecked = false;
  bool isPasswordVisible = false;
  bool isPasswordConfirmVisible = false;

  // ---------------- 아이디 검증 ----------------

  String? validateId(String raw) {
    final id = raw.trim();

    if (id.isEmpty) return '아이디를 입력해주세요.';
    if (id.length < 4 || id.length > 20) return '아이디는 4~20자여야 해요.';
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(id)) {
      return '아이디는 영문, 숫자, 점(.), 밑줄(_)만 사용할 수 있어요.';
    }

    return null;
  }

  bool get isEmailFormatValid => validateId(emailController.text) == null;

  String? get emailFormatError => validateId(emailController.text);

  // ---------------- 단계 이동 ----------------

  void previousStep() {
    if (currentStep == SignupStep.password) {
      currentStep = SignupStep.email;
    } else if (currentStep == SignupStep.userInfo) {
      currentStep = SignupStep.password;
    }

    notifyListeners();
  }

  Future<void> nextStep() async {
    if (currentStep == SignupStep.email) {
      await checkEmailDuplication();

      if (isEmailChecked) {
        currentStep = SignupStep.password;
      }
    } else if (currentStep == SignupStep.password) {
      if (isPasswordStepValid) {
        currentStep = SignupStep.userInfo;
      }
    }

    notifyListeners();
  }

  // ---------------- 아이디 중복 확인 ----------------

  Future<void> checkEmailDuplication() async {
    final id = emailController.text.trim();

    final fmtErr = validateId(id);
    if (fmtErr != null) {
      emailError = fmtErr;
      isEmailChecked = false;
      notifyListeners();
      return;
    }

    final exists = await _repo.isIdAlreadyExists(id);

    if (exists) {
      emailError = '이미 사용 중인 아이디입니다';
      isEmailChecked = false;
    } else {
      emailError = null;
      isEmailChecked = true;
    }

    notifyListeners();
  }

  // ---------------- 비밀번호 검증 ----------------

  bool get isPasswordValid {
    final password = passwordController.text.trim();
    return password.length >= 6 && password.length <= 20;
  }

  List<String> get passwordErrors {
    final password = passwordController.text.trim();
    final errors = <String>[];

    if (password.length < 6) {
      errors.add('비밀번호는 6자 이상이어야 해요.');
    }

    if (password.length > 20) {
      errors.add('비밀번호는 20자 이하여야 해요.');
    }

    return errors;
  }

  bool get isPasswordConfirmValid {
    return passwordConfirmController.text.isNotEmpty &&
        passwordConfirmController.text == passwordController.text;
  }

  bool get isPasswordStepValid {
    return isPasswordValid && isPasswordConfirmValid;
  }

  String? get passwordConfirmError {
    if (passwordConfirmController.text.isEmpty) return null;

    if (passwordConfirmController.text != passwordController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void togglePasswordConfirmVisibility() {
    isPasswordConfirmVisible = !isPasswordConfirmVisible;
    notifyListeners();
  }

  // ---------------- 닉네임 검증 ----------------

  String? validateNickname(String raw) {
    final nickname = raw.trim();

    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2~12자여야 해요.';
    }

    return null;
  }

  // ---------------- reset / submit ----------------

  void reset() {
    currentStep = SignupStep.email;

    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
    nicknameController.clear();

    signUpInfo = null;
    emailError = null;
    isLoading = false;
    isEmailChecked = false;
    isPasswordVisible = false;
    isPasswordConfirmVisible = false;

    notifyListeners();
  }

  bool get isCurrentStepValid {
    switch (currentStep) {
      case SignupStep.email:
        return isEmailFormatValid;

      case SignupStep.password:
        return isPasswordStepValid;

      case SignupStep.userInfo:
        return validateNickname(nicknameController.text) == null;
    }
  }

  bool get canSubmit {
    return currentStep == SignupStep.userInfo && isCurrentStepValid;
  }

  Future<bool> submit() async {
    isLoading = true;
    notifyListeners();

    try {
      signUpInfo = SignUpInfo(
        id: emailController.text.trim(),
        password: passwordController.text.trim(),
        nickname: nicknameController.text.trim(),
      );

      await _repo.signUp(signUpInfo!);
      return true;
    } catch (e) {
      print('회원가입 실패: $e');
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
    passwordConfirmController.dispose();
    nicknameController.dispose();
    super.dispose();
  }
}