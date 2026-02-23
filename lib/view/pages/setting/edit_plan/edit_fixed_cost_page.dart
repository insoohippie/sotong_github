import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/inputs/custom_dropdown.dart';

import '../../../../component/inputs/custom_number_field.dart';

class EditFixedCostPage extends StatefulWidget {
  const EditFixedCostPage({Key? key}) : super(key: key);

  @override
  State<EditFixedCostPage> createState() => _EditFixedCostPageState();
}

class _EditFixedCostPageState extends State<EditFixedCostPage> {
  final List<String> categories = ['월세', '통신비', '교통비', '식비', '기타'];
  final List<Map<String, dynamic>> items = [
    {'category': null, 'amount': TextEditingController()},
  ];

  void addItem() {
    setState(() {
      items.add({'category': null, 'amount': TextEditingController()});
    });
  }

  bool _isValidInput() {
    // 최소 하나의 항목이라도 카테고리와 금액이 모두 입력되었으면 유효
    for (var item in items) {
      final category = item['category'];
      final text = item['amount'].text.replaceAll(',', '');
      if (category != null && text.isNotEmpty && int.tryParse(text) != null) {
        return true;
      }
    }
    return false;
  }

  String _formatNumber(String text) {
    // 쉼표 제거 후 숫자만 추출
    final numbers = text.replaceAll(RegExp(r'[^\d]'), '');
    if (numbers.isEmpty) return '';

    // 숫자를 쉼표로 포맷팅
    final number = int.parse(numbers);
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        title: const Text(
          '플랜 수정',
          style: TextStyle(fontFamily: 'Pretendard Variable'),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '고정 지출을 입력해주세요',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '매달 고정적으로 나가는 비용이 있다면 알려주세요.',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 15,
                color: Color(0xFF7B7B7B),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomDropdown(
                          value: items[idx]['category'],
                          items: categories,
                          hintText: '지출 항목 선택',
                          onChanged: (val) {
                            setState(() {
                              items[idx]['category'] = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CustomNumberField(
                          controller: items[idx]['amount'],
                          hintText: '예: 500,000',
                          backgroundColor: const Color(0xFFF3F4F6),
                          borderRadius: 12,
                          height: 56,
                          suffix: '₩',
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: addItem,
                child: const Text(
                  '+ 항목 추가',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontFamily: 'Pretendard Variable',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // 변동사항 없음을 선택하고 다음 페이지로 이동
                      Navigator.pushNamed(context, '/edit_saving_target');
                    },
                    child: const Text(
                      '변동사항 없어요',
                      style: TextStyle(
                        color: Color(0xFF7B7B7B),
                        fontFamily: 'Pretendard Variable',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValidInput()
                        ? () {
                      // 다음 페이지로 이동하는 로직
                      Navigator.pushNamed(context, '/edit_saving_target');
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValidInput()
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(_isValidInput() ? '다음' : '다음 (입력 필요)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
