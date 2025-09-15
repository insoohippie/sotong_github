import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import '../../../component/theme/app_colors.dart';

/// ===========================================================================
/// 데이터 모델: 변동 소비 항목 (하루 기준 금액 입력)
/// ===========================================================================
class VariableExpenseEntry {
  final String category;
  final int amountPerDay;

  const VariableExpenseEntry({
    required this.category,
    required this.amountPerDay,
  });

  VariableExpenseEntry copyWith({String? category, int? amountPerDay}) {
    return VariableExpenseEntry(
      category: category ?? this.category,
      amountPerDay: amountPerDay ?? this.amountPerDay,
    );
  }
}

/// ===========================================================================
/// 입력 포맷터: 천단위 콤마 (숫자만 허용 + 커서 튐 최소화)
/// ===========================================================================
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat.decimalPattern('ko_KR');
  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = _digits(newValue.text);
    if (raw.isEmpty) return const TextEditingValue(text: '');

    final normalized = raw.replaceFirst(RegExp(r'^0+'), '');
    final formatted = _fmt.format(
      int.parse(normalized.isEmpty ? '0' : normalized),
    );

    final caret =
        formatted.length - (newValue.text.length - newValue.selection.end);

    return TextEditingValue(
      text: formatted == '0' ? '' : formatted,
      selection: TextSelection.collapsed(
        offset: caret.clamp(0, formatted.length),
      ),
    );
  }
}

/// ===========================================================================
/// 화면: 변동 소비 입력
///  - 상단 합계 컨테이너: 동그라미 배지(일/월) + 금액
///  - 각 행: 카테고리 + "하루" 금액 입력
///  - 각 행에 값이 있으면 바로 아래 "30일 기준, 한달에 XXX원이에요." 표시 (모든 행)
///  - 하단 [+ 추가]로 행을 계속 추가 가능
///  - @override 미사용, 자세한 주석 포함
/// ===========================================================================
class VariableExpensePopup extends StatefulWidget {
  const VariableExpensePopup({super.key});

  State<VariableExpensePopup> createState() => _VariableExpensePopupState();
}

class _VariableExpensePopupState extends State<VariableExpensePopup> {
  // ---------------------------- 상태 ----------------------------
  final KeyboardVisibilityController _keyboard = KeyboardVisibilityController();
  bool _isKeyboardVisible = false;

  final List<String> _categories = const ['식비', '교통비', '의류비', '문화생활비', '기타'];

  // 초기 3행 (식비/교통비/교통비)
  List<VariableExpenseEntry> _entries = const [
    VariableExpenseEntry(category: '식비', amountPerDay: 0),
    VariableExpenseEntry(category: '교통비', amountPerDay: 0),
    VariableExpenseEntry(category: '교통비', amountPerDay: 0),
  ];

  // 각 행의 텍스트 컨트롤러
  final Map<int, TextEditingController> _amountCtrls = {};

  // 안내/검증 메시지
  String _errorText = '';

  // 숫자 포매터
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');

  // ---------------------------- 라이프사이클 ----------------------------
  void initState() {
    super.initState();
    for (var i = 0; i < _entries.length; i++) {
      _amountCtrls[i] = TextEditingController();
    }
    _listenKeyboard();
  }

  Future<void> _listenKeyboard() async {
    _isKeyboardVisible = await _keyboard.isVisible;
    if (mounted) setState(() {});
    _keyboard.onChange.listen((v) {
      if (mounted) setState(() => _isKeyboardVisible = v);
    });
  }

  void dispose() {
    for (final c in _amountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------- 계산 ----------------------------
  /// 하루 합계 (원)
  int get _totalPerDay =>
      _entries.fold<int>(0, (sum, e) => sum + e.amountPerDay);

  /// 월간 합계 (원) — 30일 기준
  int get _totalPerMonth => _totalPerDay * 30;

  /// "1,234" → 1234
  int _parseAmount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  // ---------------------------- 상태 업데이트 ----------------------------
  void _updateCategory(int index, String category) {
    final list = [..._entries];
    list[index] = list[index].copyWith(category: category);
    setState(() => _entries = list);
  }

  void _updateAmountPerDay(int index, int value) {
    final list = [..._entries];
    list[index] = list[index].copyWith(amountPerDay: value);
    setState(() {
      _entries = list;
      if (_errorText.isNotEmpty) _errorText = '';
    });
  }

  bool get _hasAnyValue => _entries.any((e) => e.amountPerDay > 0);

  /// 새 행 추가 (기본 카테고리: 기타)
  void _addRow() {
    final newIndex = _entries.length;
    setState(() {
      _entries = [
        ..._entries,
        const VariableExpenseEntry(category: '기타', amountPerDay: 0),
      ];
      _amountCtrls[newIndex] = TextEditingController();
    });
  }

  // ---------------------------- 액션 ----------------------------
  void _onNext() {
    if (!_hasAnyValue) {
      setState(() => _errorText = '최소 하나의 항목을 입력해주세요.');
      return;
    }
    final valid = _entries.where((e) => e.amountPerDay > 0).toList();
    Navigator.of(context).pop(valid);
  }

  // ---------------------------- UI ----------------------------
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 (뒤로가기)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // 타이틀/서브설명
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '변동 가능성이 있는\n소비를 입력해주세요',
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      height: 1.25,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  _CaptionWithDot(text: '지출 금액을 조절할 수 있는 항목(소비)를 의미해요.'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 상단 합계 컨테이너 (일/월 배지 + 금액) — 둥근 알약 + 중앙 정렬
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400), // ⬅️ 원하는 최대 폭
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '앞으로의 생활비',
                          style: TextStyle(
                            fontFamily: 'Pretendard Variable',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _AmountChip(badgeText: '일', amountText: '${_nf.format(_totalPerDay)}원'),
                        const SizedBox(width: 10),
                        _AmountChip(badgeText: '월', amountText: '${_nf.format(_totalPerMonth)}원'),
                      ],
                    ),
                  ),
                ),
              ),
            ),




            const SizedBox(height: 10),

            // 입력 리스트 + 추가 버튼
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
                child: Column(
                  children: [
                    // 모든 행 렌더링
                    for (int i = 0; i < _entries.length; i++) ...[
                      _buildRow(
                        index: i,
                        hint: i == 0
                            ? 'ex. 500,000'
                            : i == 1
                            ? 'ex. 128,000'
                            : 'ex. 90,000',
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 에러 메시지
                    if (_errorText.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _errorText,
                          style: const TextStyle(
                            fontFamily: 'Pretendard Variable',
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // [+ 추가] 버튼
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addRow,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('추가'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFDBDBDB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),

                    SizedBox(height: _isKeyboardVisible ? 80 : 0),
                  ],
                ),
              ),
            ),

            // [다음] 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _hasAnyValue ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFFEDEDED),
                    disabledForegroundColor: const Color(0xFF9E9E9E),
                    backgroundColor: Color(0xFF0062FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text(
                    '다음',
                    style: TextStyle(fontFamily: 'Pretendard Variable'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// 단일 행: 카테고리 드롭다운 + 하루 금액 입력 + (있으면) 월간 안내문
  ///  - 이제 모든 행에서 amountPerDay > 0 이면 아래 안내문을 표시합니다.
  /// -------------------------------------------------------------------------
  Widget _buildRow({required int index, required String hint}) {
    final entry = _entries[index];
    final ctrl = _amountCtrls[index]!;
    final monthly = entry.amountPerDay * 30;
    final monthlyStr = _nf.format(monthly);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 카테고리
            Expanded(
              flex: 40,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBDBDB)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: entry.category,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontFamily: 'Pretendard Variable',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      _updateCategory(index, v);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 하루 금액 입력
            Expanded(
              flex: 60,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  style: const TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hint,
                    border: InputBorder.none,
                    hintStyle: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      color: Color(0xFFBDBDBD),
                      fontSize: 16,
                    ),
                  ),
                  onChanged: (v) => _updateAmountPerDay(index, _parseAmount(v)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // >>> 모든 행에서 값이 있을 때 안내문 표시 <<<
        if (entry.amountPerDay > 0)
          Row(
            children: [
              const Text(
                '30일 기준, 한달에 ',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
              Text(
                '$monthlyStr원',
                style: const TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '이에요.',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 14,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// ===========================================================================
/// 서브설명: 동그란 점 + 회색 텍스트
/// ===========================================================================
class _CaptionWithDot extends StatelessWidget {
  final String text;
  const _CaptionWithDot({required this.text});

  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFDADADA),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.help_outline, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 13,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ),
      ],
    );
  }
}

/// ===========================================================================
/// 상단 요약칩: 동그라미 배지 + 금액
/// ===========================================================================
class _AmountChip extends StatelessWidget {
  final String badgeText; // '일' 또는 '월'
  final String amountText;

  const _AmountChip({required this.badgeText, required this.amountText});

  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFCCE0FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 동그라미 배지 안의 '일/월'
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontFamily: 'Pretendard Variable',
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 16,
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
