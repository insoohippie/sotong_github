import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/auth/signup_info.dart';
import '../../repository/auth_repository.dart';

enum SignupStep { email, password, userInfo }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  SignupViewModel(this._repo);

  SignupStep currentStep = SignupStep.email;

  /// 기존 UI 호환을 위해 이름은 유지
  final emailController = TextEditingController(); // 실제로는 아이디 입력
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController(); // ✅ 추가
  final nameController = TextEditingController();
  final birthdayController = TextEditingController();

  String? gender;
  File? profileImage;
  SignUpInfo? signUpInfo;

  final ImagePicker _picker = ImagePicker();
  DateTime? selectedBirthday;

  String? emailError; // 실제로는 아이디 에러
  bool isLoading = false;
  bool isEmailChecked = false;
  bool isPasswordVisible = false;
  bool isPasswordConfirmVisible = false; // ✅ 추가

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
      if (isEmailChecked) currentStep = SignupStep.password;
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
    final password = passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar =
    RegExp(r'''[!@#\$&*~%^()_\-+=\[\]{}|\\:;"'<>,.?/]''').hasMatch(password);

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
    if (!RegExp(r'''[!@#\$&*~%^()_\-+=\[\]{}|\\:;"'<>,.?/]''')
        .hasMatch(password)) {
      errors.add('특수문자를 하나 이상 포함해야 해요.');
    }

    return errors;
  }

  bool get isPasswordConfirmValid =>
      passwordConfirmController.text.isNotEmpty &&
          passwordConfirmController.text == passwordController.text;

  bool get isPasswordStepValid => isPasswordValid && isPasswordConfirmValid;

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

  // ---------------- reset / submit ----------------
  void reset() {
    currentStep = SignupStep.email;
    emailController.clear();
    passwordController.clear();
    passwordConfirmController.clear();
    nameController.clear();
    gender = '';
    birthdayController.text = '';
    isEmailChecked = false;
    signUpInfo = null;
    emailError = null;
    isLoading = false;
    isPasswordVisible = false;
    isPasswordConfirmVisible = false;
    profileImage = null;
    selectedBirthday = null;
    notifyListeners();
  }

  bool get isCurrentStepValid {
    switch (currentStep) {
      case SignupStep.email:
        return isEmailFormatValid;
      case SignupStep.password:
        return isPasswordStepValid;
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
        id: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        birthday: birthdayController.text.trim(),
        gender: gender ?? '',
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

  // ---------------- 기타 ----------------
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    nameController.dispose();
    birthdayController.dispose();
    super.dispose();
  }
}