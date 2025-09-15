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

  void _selectOption(String option) {
    setState(() {
      _selectedOption = option;
    });
  }

  void _proceed() {
    if (_selectedOption == null) return;

    if (_selectedOption == 'period') {
      Navigator.of(context).pushReplacementNamed('/period_loading');
    } else if (_selectedOption == 'limit') {
      Navigator.of(context).pushReplacementNamed('/limit_loading');
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.sectionSpacing2),

                    // 메인 텍스트
                    const Text(
                      '금액에 변화가 생겼어요.\n소비 한도나 목표 달성 기간을 변경하시겠어요?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.4,
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
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _selectOption('period'),
                              child: Center(
                                child: Text(
                                  '기간을 줄일래요',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedOption == 'period'
                                        ? AppColors.primary
                                        : Colors.grey[600],
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
                                  ? AppColors.primary
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _selectOption('limit'),
                              child: Center(
                                child: Text(
                                  '소비 한도를 늘릴래요',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedOption == 'limit'
                                        ? AppColors.primary
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // 확인 버튼
                    Container(
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}