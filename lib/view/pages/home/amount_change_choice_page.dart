import 'package:flutter/material.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

class AmountChangeChoicePage extends StatefulWidget {
  final String amount;

  const AmountChangeChoicePage({super.key, required this.amount});

  @override
  State<AmountChangeChoicePage> createState() => _AmountChangeChoicePageState();
}

class _AmountChangeChoicePageState extends State<AmountChangeChoicePage> {
  String? _selectedOption;
  String? _descriptionMessage;

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
      if (option == 'period') {
        _descriptionMessage = '1,000,000원을 기간에 반영하면 30일이 줄어들어요!';
      } else if (option == 'limit') {
        _descriptionMessage =
            '1,000,000원을 소비한도 금액에 반영하면 하루에 10,000원에서 20,000원으로 늘어나요!';
      }
    });
  }

  Widget _buildDescriptionText() {
    if (_selectedOption == 'period') {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard Variable',
            color: Colors.black87,
            height: 1.4,
          ),
          children: [
            TextSpan(text: ''),
            TextSpan(
              text: '1,000,000원',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '을 기간에 반영하면 '),
            TextSpan(
              text: '30일',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '이 줄어들어요!'),
          ],
        ),
      );
    } else if (_selectedOption == 'limit') {
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard Variable',
            color: Colors.black87,
            height: 1.4,
          ),
          children: [
            TextSpan(text: ''),
            TextSpan(
              text: '1,000,000원',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '을 소비한도 금액에 반영하면\n하루에 '),
            TextSpan(
              text: '10,000원',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '에서 '),
            TextSpan(
              text: '20,000원',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: '으로 늘어나요!'),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _proceed() {
    if (_selectedOption == null) return;

    if (_selectedOption == 'period') {
      Navigator.of(context).pushReplacementNamed('/period_success');
    } else if (_selectedOption == 'limit') {
      Navigator.of(context).pushReplacementNamed('/limit_success');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(title: '', onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sectionSpacing2),

                    // 메인 텍스트 (2줄, 왼쪽 정렬, 파란색 강조, 특정 글자 검정색)
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

                    // 선택 옵션들
                    Column(
                      children: [
                        // 기간을 줄일래요 버튼
                        Container(
                          width: double.infinity,
                          height: 56,
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.fieldSpacing,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedOption == 'period'
                                ? AppColors.lightBlue
                                : Colors.white,
                            border: Border.all(
                              color: _selectedOption == 'period'
                                  ? Colors.transparent
                                  : Colors.grey[300]!,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _selectOption('period'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '기간을 줄일래요',
                                    style: TextStyle(
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
                        ),

                        // 소비 한도를 늘릴래요 버튼
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _selectedOption == 'limit'
                                ? AppColors.lightBlue
                                : Colors.white,
                            border: Border.all(
                              color: _selectedOption == 'limit'
                                  ? Colors.transparent
                                  : Colors.grey[300]!,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _selectOption('limit'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '소비한도를 늘릴래요',
                                    style: TextStyle(
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
                        ),
                      ],
                    ),

                    // 설명 메시지
                    if (_descriptionMessage != null) ...[
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
                        child: _buildDescriptionText(),
                      ),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 네비게이션 바에 고정된 확인 버튼
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
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
}
