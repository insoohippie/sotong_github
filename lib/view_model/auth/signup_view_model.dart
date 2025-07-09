import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/signup_info.dart';
import '../../repository/auth_repository.dart';

enum SignupStep { email, password, userInfo }

class SignupViewModel extends ChangeNotifier {
  final AuthRepository _repo;
  SignupViewModel(this._repo);

  // 스텝
  SignupStep currentStep = SignupStep.email;

  // 입력값 컨트롤러
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final birthdayController = TextEditingController();
  String? gender;
  File? profileImage;

  final ImagePicker _picker = ImagePicker();
  DateTime? selectedBirthday;
  String? emailError;
  bool isLoading = false;
  bool isEmailChecked = false;

  /// 이전 단계로 이동
  void previousStep() {
    if (currentStep == SignupStep.password) {
      currentStep = SignupStep.email;
    } else if (currentStep == SignupStep.userInfo) {
      currentStep = SignupStep.password;
    }
    notifyListeners();
  }

  /// 다음 단계로 이동
  Future<void> nextStep() async {
    if (currentStep == SignupStep.email) {
      await checkEmailDuplication();
      if (isEmailChecked) currentStep = SignupStep.password;
    } else if (currentStep == SignupStep.password) {
      currentStep = SignupStep.userInfo;
    }
    notifyListeners();
  }

  // 이메일 유효성 판단
  bool get isEmailFormatValid =>
      emailController.text.isNotEmpty &&
          RegExp(r'\S+@\S+\.\S+').hasMatch(emailController.text);
  //비밀번호 유효성 판단
  bool get isPasswordValid {
    final password = passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|\\:;"\<>,.?/]').hasMatch(password);

    return hasMinLength && hasUppercase && hasSpecialChar && hasNumber;
    }

  // 현재 스텝에서 다음 버튼 활성화 조건
  bool get isCurrentStepValid {
    switch (currentStep) {
      case SignupStep.email:
        return isEmailFormatValid;
      case SignupStep.password:
        return passwordController.text.length >= 6;
      case SignupStep.userInfo:
        return nameController.text.isNotEmpty &&
            birthdayController.text.isNotEmpty &&
            gender != null;
    }
  }

  // 이메일 중복 확인
  Future<void> checkEmailDuplication() async {
    final email = emailController.text.trim();
    if (!isEmailFormatValid) {
      emailError = '이메일 형식이 올바르지 않습니다';
      isEmailChecked = false;
    } else {
      final exists = await _repo.isEmailAlreadyExists(email);
      if (exists) {
        emailError = '이미 가입된 이메일입니다';
        isEmailChecked = false;
      } else {
        emailError = null;
        isEmailChecked = true;
      }
    }
    notifyListeners();
  }

  // 날짜 선택
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

  bool get canSubmit =>
      currentStep == SignupStep.userInfo && isCurrentStepValid;

  Future<bool> submit() async {
    isLoading = true;
    notifyListeners();

    try {
      final userInfo = SignUpInfo(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        name: nameController.text.trim(),
        birthday: birthdayController.text.trim(),
        gender: gender ?? '',
      );

      await _repo.signUp(userInfo, profileImage);
      return true;
    } catch (e) {
      print('회원가입 실패: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

