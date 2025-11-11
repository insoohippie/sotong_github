import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/auth/signup_info.dart';
import '../../repository/auth_repository.dart';

enum SignupStep { email, password, userInfo }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  SignupViewModel(this._repo);

  // ───────────────────────────────── 스텝 & 상태 ─────────────────────────────────
  SignupStep currentStep = SignupStep.email;

  // 입력 컨트롤러
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final birthdayController = TextEditingController();

  String? gender;
  File? profileImage;
  SignUpInfo? signUpInfo;

  final ImagePicker _picker = ImagePicker();
  DateTime? selectedBirthday;

  String? emailError; // 형식/중복 에러 통합 표시
  bool isLoading = false;
  bool isEmailChecked = false;
  bool isPasswordVisible = false;

  // ───────────────────────────────── 이메일 검증 ─────────────────────────────────
  /// 세분화된 이메일 유효성 검사 (현실적인 제약)
  /// - 전체 ≤ 254, 로컬 ≤ 64
  /// - 연속 점/양끝 점 금지
  /// - 도메인: label.label 구조, 각 라벨 앞뒤 하이픈 금지
  /// - TLD: 2–24자 알파벳
  String? validateEmail(String raw) {
    final email = raw.trim();

    if (email.isEmpty) return '이메일을 입력해주세요.';
    if (email.length > 254) return '이메일이 너무 깁니다.';

    // '@' 정확히 1개
    final atCount = '@'.allMatches(email).length;
    if (atCount != 1) return '이메일 형식이 올바르지 않습니다.';

    final parts = email.split('@');
    final local = parts[0];
    final domain = parts[1].toLowerCase();

    if (local.isEmpty || domain.isEmpty) return '이메일 형식이 올바르지 않습니다.';
    if (local.length > 64) return '로컬 파트가 너무 깁니다.';

    // 로컬 파트: 앞/뒤 점 금지, 연속 점 금지, 허용 문자셋
    final localOk = RegExp(
      r"^(?!\.)(?!.*\.\.)[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+(?<!\.)$",
    ).hasMatch(local);
    if (!localOk) return '로컬 파트 형식이 올바르지 않습니다.';

    // 도메인: label.label..., 각 라벨은 앞뒤 하이픈 금지, 전체 길이 ≤ 253
    final domainOk = RegExp(
      r'^(?=.{1,253}$)([A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,24}$',
    ).hasMatch(domain);
    if (!domainOk) return '도메인 형식이 올바르지 않습니다.';

    return null; // 유효
  }

  bool get isEmailFormatValid => validateEmail(emailController.text) == null;
  String? get emailFormatError => validateEmail(emailController.text);

  // ─────────────────────────────── 스텝 이동 ───────────────────────────────
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
      if (isEmailChecked) currentStep = SignupStep.password;
    } else if (currentStep == SignupStep.password) {
      currentStep = SignupStep.userInfo;
    }
    notifyListeners();
  }

  // ───────────────────────────── 이메일 중복 확인 ─────────────────────────────
  Future<void> checkEmailDuplication() async {
    final email = emailController.text.trim();

    // 형식 우선 검증
    final fmtErr = validateEmail(email);
    if (fmtErr != null) {
      emailError = fmtErr;
      isEmailChecked = false;
      notifyListeners();
      return;
    }

    // 중복 체크
    final exists = await _repo.isEmailAlreadyExists(email);
    if (exists) {
      emailError = '이미 가입된 이메일입니다';
      isEmailChecked = false;
    } else {
      emailError = null;
      isEmailChecked = true;
    }
    notifyListeners();
  }

  // ───────────────────────────── 비밀번호 유효성 ─────────────────────────────
  bool get isPasswordValid {
    final password = passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar = RegExp(
      r'''[!@#\$&*~%^()_\-+=\[\]{}|\\:;"'<>,.?/]''',
    ).hasMatch(password);
    return hasMinLength && hasUppercase && hasSpecialChar && hasNumber;
  }

  List<String> get passwordErrors {
    final password = passwordController.text;
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('8자 이상이어야 해요.');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('대문자를 하나 이상 포함해야 해요.');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      errors.add('숫자를 하나 이상 포함해야 해요.');
    }
    if (!RegExp(r'''[!@#\$&*~%^()_\-+=\[\]{}|\\:;"'<>,.?/]''').hasMatch(password)) {
      errors.add('특수문자를 하나 이상 포함해야 해요.');
    }

    return errors;
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  // ───────────────────────────── 리셋/유효성/제출 ─────────────────────────────
  void reset() {
    currentStep = SignupStep.email;
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    gender = '';
    birthdayController.text = '';
    isEmailChecked = false;
    signUpInfo = null;
    emailError = null;
    isLoading = false;
    isPasswordVisible = false;
    profileImage = null;
    selectedBirthday = null;
    notifyListeners();
  }

  bool get isCurrentStepValid {
    switch (currentStep) {
      case SignupStep.email:
        return isEmailFormatValid;
      case SignupStep.password:
        return isPasswordValid;
      case SignupStep.userInfo:
        return nameController.text.isNotEmpty &&
            birthdayController.text.isNotEmpty &&
            gender != null &&
            gender!.isNotEmpty;
    }
  }

  bool get canSubmit =>
      currentStep == SignupStep.userInfo && isCurrentStepValid;

  Future<bool> submit() async {
    isLoading = true;
    notifyListeners();

    try {
      signUpInfo = SignUpInfo(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        birthday: birthdayController.text.trim(),
        gender: gender ?? '',
      );

      await _repo.signUp(signUpInfo!);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('회원가입 실패: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────── 날짜/성별/이미지 ─────────────────────────────
  Future<void> pickBirthday(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      selectedBirthday = pickedDate;
      birthdayController.text =
      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      notifyListeners();
    }
  }

  void setBirthdayFromCupertino(DateTime pickedDate) {
    selectedBirthday = pickedDate;
    birthdayController.text =
    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    notifyListeners();
  }

  void setGender(String? value) {
    gender = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      profileImage = File(image.path);
      notifyListeners();
    }
  }

  // ───────────────────────────── 메모리 정리 ─────────────────────────────
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    birthdayController.dispose();
    super.dispose();
  }
}
