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
  String? submitError;

  bool isLoading = false;
  bool isCheckingId = false;
  bool isEmailChecked = false;
  bool showCurrentStepErrors = false;

  bool isPasswordVisible = false;
  bool isPasswordConfirmVisible = false;

  /// 아이디 중복 확인 또는 회원가입 진행 중
  bool get isBusy => isLoading || isCheckingId;

  // =========================================================
  // 아이디 검증
  // =========================================================

  String? validateId(String raw) {
    final id = raw.trim();

    if (id.isEmpty) {
      return '아이디를 입력해주세요.';
    }

    if (id.length < 4 || id.length > 20) {
      return '아이디는 4~20자여야 해요.';
    }

    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(id)) {
      return '아이디는 영문, 숫자, 점(.), 밑줄(_)만 사용할 수 있어요.';
    }

    return null;
  }

  bool get isEmailFormatValid {
    return validateId(emailController.text) == null;
  }

  String? get emailFormatError {
    return validateId(emailController.text);
  }

  /// 아이디 입력값이 변경되면 기존 중복 확인 결과를 초기화
  void onIdChanged(String value) {
    isEmailChecked = false;
    submitError = null;

    if (showCurrentStepErrors) {
      emailError = validateId(value);
    } else {
      emailError = null;
    }

    notifyListeners();
  }

  /// 비밀번호, 비밀번호 확인, 닉네임 입력 변경
  void onFieldChanged(String value) {
    submitError = null;
    notifyListeners();
  }

  // =========================================================
  // 단계 이동
  // =========================================================

  void previousStep() {
    if (currentStep == SignupStep.password) {
      currentStep = SignupStep.email;
    } else if (currentStep == SignupStep.userInfo) {
      currentStep = SignupStep.password;
    }

    showCurrentStepErrors = false;
    submitError = null;

    notifyListeners();
  }

  Future<void> nextStep() async {
    if (isBusy) {
      return;
    }

    showCurrentStepErrors = true;
    submitError = null;
    notifyListeners();

    if (currentStep == SignupStep.email) {
      await checkEmailDuplication();

      if (!isEmailChecked) {
        return;
      }

      currentStep = SignupStep.password;
      showCurrentStepErrors = false;
    } else if (currentStep == SignupStep.password) {
      if (!isPasswordStepValid) {
        notifyListeners();
        return;
      }

      currentStep = SignupStep.userInfo;
      showCurrentStepErrors = false;
    }

    notifyListeners();
  }

  // =========================================================
  // 아이디 중복 확인
  // =========================================================

  Future<void> checkEmailDuplication() async {
    final id = emailController.text.trim();

    final formatError = validateId(id);

    if (formatError != null) {
      emailError = formatError;
      isEmailChecked = false;
      notifyListeners();
      return;
    }

    isCheckingId = true;
    emailError = null;
    isEmailChecked = false;
    notifyListeners();

    try {
      final exists = await _repo.isIdAlreadyExists(id);

      /// 확인 요청 중 사용자가 아이디를 변경했다면
      /// 이전 아이디의 확인 결과를 적용하지 않음
      if (emailController.text.trim() != id) {
        return;
      }

      if (exists) {
        emailError = '이미 사용 중인 아이디입니다.';
        isEmailChecked = false;
      } else {
        emailError = null;
        isEmailChecked = true;
      }
    } catch (e) {
      if (emailController.text.trim() == id) {
        emailError = '아이디 확인 중 오류가 발생했습니다. 다시 시도해주세요.';
        isEmailChecked = false;
      }

      debugPrint('아이디 중복 확인 실패: $e');
    } finally {
      isCheckingId = false;
      notifyListeners();
    }
  }

  // =========================================================
  // 비밀번호 검증
  // =========================================================

  bool get isPasswordValid {
    final password = passwordController.text;

    return password.length >= 6 && password.length <= 20;
  }

  List<String> get passwordErrors {
    final password = passwordController.text;
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
    if (passwordConfirmController.text.isEmpty) {
      return null;
    }

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

  // =========================================================
  // 닉네임 검증
  // =========================================================

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

  // =========================================================
  // 초기화
  // =========================================================

  void reset() {
    currentStep = SignupStep.email;

    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
    nicknameController.clear();

    signUpInfo = null;

    emailError = null;
    submitError = null;

    isLoading = false;
    isCheckingId = false;
    isEmailChecked = false;
    showCurrentStepErrors = false;

    isPasswordVisible = false;
    isPasswordConfirmVisible = false;

    notifyListeners();
  }

  // =========================================================
  // 현재 단계 검증
  // =========================================================

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

  // =========================================================
  // 오류 메시지 변환
  // =========================================================

  String _getErrorMessage(Object error) {
    final message = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();

    if (message.contains('email-already-in-use')) {
      return '이미 사용 중인 아이디입니다.';
    }

    if (message.contains('network-request-failed') ||
        message.contains('unavailable')) {
      return '인터넷 연결을 확인해주세요.';
    }

    if (message.isEmpty || message.startsWith('[')) {
      return '회원가입 중 오류가 발생했습니다.';
    }

    return message;
  }

  // =========================================================
  // 회원가입
  // =========================================================

  Future<bool> submit() async {
    if (isBusy) {
      return false;
    }

    showCurrentStepErrors = true;
    submitError = null;

    if (!canSubmit) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();

    try {
      signUpInfo = SignUpInfo(
        id: emailController.text.trim(),

        /// 비밀번호 앞뒤 공백도 입력값에 포함되도록 trim 사용하지 않음
        password: passwordController.text,
        nickname: nicknameController.text.trim(),
      );

      await _repo.signUp(signUpInfo!);

      return true;
    } catch (e) {
      submitError = _getErrorMessage(e);

      debugPrint('회원가입 실패: $e');

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