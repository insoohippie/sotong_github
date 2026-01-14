import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../component/appbars/custom_app_bar.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../component/theme/app_spacing.dart';
import '../../../../view_model/addIncome/add_income_view_model.dart';

class ApplyIncomeOptionPage extends StatefulWidget {
  const ApplyIncomeOptionPage({super.key});

  @override
  State<ApplyIncomeOptionPage> createState() => _ApplyIncomeOptionPageState();
}

class _ApplyIncomeOptionPageState extends State<ApplyIncomeOptionPage> {
  String? _selectedOption; // 'period' or 'limit'

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  Widget _buildDescriptionText(AddIncomeViewModel vm) {
    if (_selectedOption == 'period') {
      return Text(
        vm.periodPreviewText, // ex) "1,000,000원을 기간에 반영하면 30일이 줄어들어요!"
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard Variable',
          color: Colors.black87,
          height: 1.4,
        ),
      );
    } else if (_selectedOption == 'limit') {
      return Text(
        vm.limitPreviewText, // ex) "1,000,000원을 소비한도 금액에 반영하면..."
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard Variable',
          color: Colors.black87,
          height: 1.4,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _proceed() {
    if (_selectedOption == null) return;

    if (_selectedOption == 'period') {
      Navigator.of(context).pushReplacementNamed('/period_apply');
    } else if (_selectedOption == 'limit') {
      Navigator.of(context).pushReplacementNamed('/limit_apply');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddIncomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: '',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sectionSpacing2),

                    // 메인 텍스트
                    RichText(
                      textAlign: TextAlign.left,
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '지출에 변화가 생겼어요.\n'),
                          TextSpan(
                            text: '소비 한도',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(
                            text: '나',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: ' 목표 달성 기간',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          TextSpan(
                            text: '을',
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: '\n변경하시겠어요?',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sectionSpacing2),

                    // 선택 옵션
                    Column(
                      children: [
                        // 기간
                        _buildOptionButton(
                          label: '기간을 줄일래요',
                          selected: _selectedOption == 'period',
                          onTap: () => _selectOption('period'),
                        ),
                        const SizedBox(height: AppSpacing.fieldSpacing),
                        // 한도
                        _buildOptionButton(
                          label: '소비한도를 늘릴래요',
                          selected: _selectedOption == 'limit',
                          onTap: () => _selectOption('limit'),
                        ),
                      ],
                    ),

                    // 설명 메시지
                    if (_selectedOption != null) ...[
                      const SizedBox(height: AppSpacing.sectionSpacing2),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: _buildDescriptionText(vm),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: const BoxDecoration(color: Colors.white),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedOption != null ? _proceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedOption != null
                        ? AppColors.primary
                        : AppColors.disabled,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: selected ? AppColors.lightBlue : Colors.white,
        border: Border.all(
          color: selected ? Colors.transparent : Colors.grey[300]!,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard Variable',
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
