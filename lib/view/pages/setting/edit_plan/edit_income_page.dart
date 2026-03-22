import 'package:flutter/material.dart';
import '../../../../component/appbars/back_only_app_bar.dart';
import 'package:flutter/services.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

import '../../../../component/inputs/custom_number_field.dart';

class EditIncomePage extends StatefulWidget {
  const EditIncomePage({Key? key}) : super(key: key);

  @override
  State<EditIncomePage> createState() => _EditIncomePageState();
}

class _EditIncomePageState extends State<EditIncomePage> {
  final TextEditingController _controller = TextEditingController();
  bool _isValidInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      // 숫자만 있는지 확인 (쉼표 제외)
      final text = _controller.text.replaceAll(',', '');
      _isValidInput = text.isNotEmpty && int.tryParse(text) != null;
    });
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
      appBar: const BackOnlyAppBar(title: '플랜 수정'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 월 수입을 알려주세요',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '아르바이트, 월급, 용돈 등 포함해서 입력해주세요.',
              style: TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 15,
                color: Color(0xFF7B7B7B),
              ),
            ),
            const SizedBox(height: 32),
            CustomNumberField(
              controller: _controller,
              hintText: '예: 2,400,000',
              backgroundColor: const Color(0xFFF3F4F6),
              borderRadius: 12,
              height: 56,
              suffix: '₩',
              onChanged: (value) {
                setState(() {
                  final text = value.replaceAll(',', '');
                  _isValidInput = text.isNotEmpty && int.tryParse(text) != null;
                });
              },
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {},
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
                    onPressed: _isValidInput
                        ? () {
                      // 다음 페이지로 이동하는 로직
                      Navigator.pushNamed(context, '/edit_fixed_cost');
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValidInput
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
                    child: const Text('다음'),
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
