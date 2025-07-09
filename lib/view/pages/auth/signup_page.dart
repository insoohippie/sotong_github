import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';

import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../view_model/auth/signup_view_model.dart';
import '../../../component/buttons/custom_button.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: '',
              onBack: () {
                if (vm.currentStep == SignupStep.email) {
                  Navigator.pop(context);
                } else {
                  vm.previousStep();
                }
              }
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  children: [
                    //이메일 입력, 비밀번호 입력, 유저정보 입력을 스텝으로 진행
                    if (vm.currentStep == SignupStep.email) _buildEmailField(vm),
                    if (vm.currentStep == SignupStep.password) _buildPasswordField(vm),
                    if (vm.currentStep == SignupStep.userInfo) _buildUserInfoField(context, vm),
                  ],
                ),
              ),
            ),
            CustomButton(
              text: vm.currentStep == SignupStep.userInfo ? '회원가입 완료' : '다음',
              enabled: vm.isCurrentStepValid,
              onPressed: () async {
                if (vm.currentStep == SignupStep.userInfo && vm.canSubmit) {
                  final success = await vm.submit();
                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } else {
                  await vm.nextStep();
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '이메일을 입력하세요'),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.emailController,
          hintText: 'ex. sotong@google.com',
          onChanged: (_) => vm.notifyListeners(),
        ),
        SizedBox(height: AppSpacing.itemSpacing),
        if (vm.emailError != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              vm.emailError!,
              style: AppTextStyles.errorText,
            ),
          )
        else if (vm.isEmailChecked)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '중복 확인 완료',
              style: AppTextStyles.infoText,
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField(SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '비밀번호를 설정해주세요'),
        SizedBox(height: AppSpacing.fieldSpacing),
        CustomTextField(
          controller: vm.passwordController,
          hintText: '8자리 이상의 숫자, 특수문자, 대문자',
          onChanged: (_) => vm.notifyListeners(),
        ),
      ],
    );
  }

  Widget _buildUserInfoField(BuildContext context, SignupViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderText(text: '아래 정보만 입력하면'),
        HeaderText(text: '회원가입 완료!'),
        const SizedBox(height: 24),
        ParagraphText(text: '이름'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: vm.emailController.text.isEmpty
                ? const Color(0xFFEDEDED)
                : const Color(0xFFEDF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: vm.nameController,
            decoration: const InputDecoration(
              hintText: '이름 입력',
              border: InputBorder.none,
            ),
            onChanged: (_) => vm.notifyListeners(),
          ),
        ),
        const SizedBox(height: 16),
        ParagraphText(text: '생년월일'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showWheelDatePicker(context, vm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: vm.birthdayController.text.isEmpty
                  ? Colors.grey[200]
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vm.birthdayController.text.isEmpty
                  ? '생년월일을 선택하세요'
                  : vm.birthdayController.text,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ParagraphText(text: '성별'),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderButton(vm, '남자'),
            const SizedBox(width: 16),
            _genderButton(vm, '여자'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _genderButton(SignupViewModel vm, String gender) {
    final isSelected = vm.gender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => vm.setGender(gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              gender,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> showWheelDatePicker(BuildContext context, SignupViewModel vm) async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime(2000, 1, 1),
                  minimumYear: 1900,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (DateTime date) {
                    vm.setBirthdayFromCupertino(date);
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              )
            ],
          ),
        );
      },
    );
  }
}
