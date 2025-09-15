import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../component/appbars/custom_app_bar.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../model/income_entry.dart';

class HomeAddIncomePage extends StatefulWidget {
  const HomeAddIncomePage({super.key});

  @override
  State<HomeAddIncomePage> createState() => _HomeAddIncomePageState();
}

class _HomeAddIncomePageState extends State<HomeAddIncomePage> {
  List<IncomeEntry> _incomeEntries = [];
  final List<String> _categories = [
    '용돈',
    '장학금',
    '지원금',
    '급여',
    '부업',
    '투자수익',
    '기타(직접입력)',
  ];

  @override
  void initState() {
    super.initState();
    _addNewEntry();
  }

  void _addNewEntry() {
    setState(() {
      _incomeEntries.add(IncomeEntry(category: '용돈'));
    });
  }

  void _updateEntry(int index, IncomeEntry entry) {
    setState(() {
      _incomeEntries[index] = entry;
    });
  }

  void _saveIncome() {
    // 빈 항목들 제거
    final validEntries = _incomeEntries
        .where((entry) => !entry.isEmpty)
        .toList();

    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최소 하나의 입금 내역을 입력해주세요')));
      return;
    }

    // 총 금액 계산
    int totalAmount = 0;
    for (final entry in validEntries) {
      if (entry.amount != null) {
        final cleanAmount = entry.amount!.replaceAll(',', '');
        totalAmount += int.tryParse(cleanAmount) ?? 0;
      }
    }

    // TODO: 실제 저장 로직 구현
    // 금액 변화 선택 페이지로 이동
    Navigator.of(context).pushReplacementNamed(
      '/amount_change_choice',
      arguments:
      '${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: '추가 입금',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 입금 내역들
                    ...List.generate(_incomeEntries.length, (index) {
                      return _buildIncomeEntry(index);
                    }),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // 입금내역 추가 버튼
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _addNewEntry,
                            child: const Center(
                              child: Text(
                                '입금내역 추가 +',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 다음 버튼
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeEntry(int index) {
    final entry = _incomeEntries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.fieldSpacing),
      child: Column(
        children: [
          // 카테고리 선택
          _buildCategoryField(index, entry),
          const SizedBox(height: AppSpacing.fieldSpacing),

          // 내용 입력
          _buildContentField(index, entry),
          const SizedBox(height: AppSpacing.fieldSpacing),

          // 금액 입력
          _buildAmountField(index, entry),
        ],
      ),
    );
  }

  Widget _buildCategoryField(int index, IncomeEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.subText),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: entry.category,
          isExpanded: true,
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _updateEntry(
                index,
                IncomeEntry(
                  category: newValue,
                  content: entry.content,
                  amount: entry.amount,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildContentField(int index, IncomeEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.subText),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: TextEditingController(text: entry.content ?? ''),
        decoration: const InputDecoration(
          hintText: '내용',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          _updateEntry(
            index,
            IncomeEntry(
              category: entry.category,
              content: value.isEmpty ? null : value,
              amount: entry.amount,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmountField(int index, IncomeEntry entry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.subText),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: TextEditingController(text: entry.amount ?? ''),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(
                hintText: '금액',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _updateEntry(
                  index,
                  IncomeEntry(
                    category: entry.category,
                    content: entry.content,
                    amount: value.isEmpty ? null : value,
                  ),
                );
              },
            ),
          ),
          const Text(
            '원',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(',', '');
    final number = int.tryParse(cleanText);

    if (number == null) {
      return oldValue;
    }

    final formattedText = _formatNumber(number);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }

  String _formatNumber(int number) {
    final String numberStr = number.toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < numberStr.length; i++) {
      if (i > 0 && (numberStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(numberStr[i]);
    }

    return buffer.toString();
  }
}