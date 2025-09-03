import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/appbars/custom_app_bar.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/containers/rounded_info_container.dart';

import '../../../../component/buttons/small_rounded_button.dart';
import '../../../../component/inputs/custom_number_field.dart';
import '../../../../component/inputs/custom_text_field.dart';
import '../../../../component/texts/header_text.dart';
import '../../../../component/texts/paragraph_text.dart';
import '../../../../component/texts/subtext.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../model/entry.dart';

class InputModalWidget extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String title;
  final Function(List<Entry>, double) onComplete;
  final String placeholder;
  final String hintText;
  final EntryType type;
  final List<Entry>? initialEntries;

  const InputModalWidget({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.title,
    required this.onComplete,
    required this.type,
    this.placeholder = '수입 카테고리 (예: 급여)',
    this.hintText = '예: 월급, 아르바이트, 용돈 등',
    this.initialEntries,
  }) : super(key: key);

  @override
  State<InputModalWidget> createState() => _InputModalWidgetState();
}

class _InputModalWidgetState extends State<InputModalWidget> {
  // ────────────────────────────────────────────────────────────────────────────
  // State
  // ────────────────────────────────────────────────────────────────────────────
  List<Entry> items = [];
  String error = '';

  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _categoryControllers = {};
  final Map<int, FocusNode> _categoryFocusNodes = {};
  final Map<int, FocusNode> _amountFocusNodes = {};

  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _isKeyboardVisible = false;

  // ────────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _keyboardVisibilityController = KeyboardVisibilityController();
    _initKeyboardVisibility();
    _initItems(widget.initialEntries);
  }

  Future<void> _initKeyboardVisibility() async {
    _isKeyboardVisible = await _keyboardVisibilityController.isVisible;
    setState(() {});
    _keyboardVisibilityController.onChange.listen((visible) {
      setState(() => _isKeyboardVisible = visible);
    });
  }

  void _initItems(List<Entry>? initial) {
    if (initial != null && initial.isNotEmpty) {
      items = List<Entry>.from(initial);
      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }
    } else {
      final seed = Entry(
        idx: DateTime.now().millisecondsSinceEpoch,
        amount: 0,
        category: '',
        type: widget.type,
      );
      items = [seed];
      _initializeControllers(seed.idx, seed.category, seed.amount);
    }
  }

  String _unformat(String v) => v.replaceAll(',', '');
  String _format(String v) {
    if (v.isEmpty) return '';
    final n = int.tryParse(_unformat(v));
    if (n == null) return '';
    return NumberFormat('#,###').format(n);
  }


  @override
  void dispose() {
    for (final c in _amountControllers.values) c.dispose();
    for (final c in _categoryControllers.values) c.dispose();
    for (final f in _categoryFocusNodes.values) f.dispose();
    for (final f in _amountFocusNodes.values) f.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Utils
  // ────────────────────────────────────────────────────────────────────────────
  void _initializeControllers(int idx, String category, double amount) {
    _categoryControllers[idx] = TextEditingController(text: category);
    _amountControllers[idx] = TextEditingController(
      text: amount > 0 ? _formatNumber(amount.toStringAsFixed(0)) : '',
    );
    _categoryFocusNodes[idx] = FocusNode();
    _amountFocusNodes[idx] = FocusNode();
  }

  String _unformatNumber(String value) => value.replaceAll(',', '');

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final n = int.tryParse(_unformatNumber(value));
    if (n == null) return '';
    return NumberFormat('#,###').format(n);
  }

  double getTotalAmount() =>
      items.fold<double>(0, (sum, item) => sum + item.amount);

  // ────────────────────────────────────────────────────────────────────────────
  // Mutations
  // ────────────────────────────────────────────────────────────────────────────
  void addItem() {
    final newIdx = DateTime.now().millisecondsSinceEpoch + items.length;
    setState(() {
      items.add(Entry(idx: newIdx, amount: 0, category: '', type: widget.type));
      _initializeControllers(newIdx, '', 0);
      if (error.isNotEmpty) error = '';
    });
  }

  void updateItem(int idx, String field, dynamic value) {
    final i = items.indexWhere((e) => e.idx == idx);
    if (i == -1) return;

    if (field == 'category') {
      items[i].category = value as String;
    } else if (field == 'amount') {
      items[i].amount = value as double;
    }
    if (error.isNotEmpty) setState(() => error = '');
  }

  void removeItem(int idx) {
    setState(() {
      items.removeWhere((e) => e.idx == idx);
      _categoryControllers[idx]?.dispose();
      _amountControllers[idx]?.dispose();
      _categoryFocusNodes[idx]?.dispose();
      _amountFocusNodes[idx]?.dispose();
      _categoryControllers.remove(idx);
      _amountControllers.remove(idx);
      _categoryFocusNodes.remove(idx);
      _amountFocusNodes.remove(idx);
      if (error.isNotEmpty) error = '';
    });
  }

  void handleComplete() {
    final validItems =
    items.where((e) => e.category.isNotEmpty && e.amount > 0).toList();
    final hasEmptyCategory =
    items.any((e) => e.amount > 0 && e.category.trim().isEmpty);

    if (hasEmptyCategory) {
      setState(() => error = '카테고리명을 정확히 입력해주세요.');
      return;
    }
    if (validItems.isEmpty) {
      setState(() => error = '최소 하나의 항목을 입력해주세요.');
      return;
    }

    widget.onComplete(validItems, getTotalAmount());
    widget.onClose();
    setState(() => error = '');
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Labels / Description
  // ────────────────────────────────────────────────────────────────────────────
  String getDetailDescription() {
    if (widget.title.contains('월 수입')) {
      return '💡 <b>월 수입이란?</b>\n'
          '- 매달 반복적으로 들어오는 모든 수입을 말해요.\n'
          '- 매달 금액이 일정하지 않다면 최근 3개월 평균으로 입력해 주세요.\n\n'
          '✍ <b>입력 가이드</b>\n'
          '- 수입이 여러 가지라면 항목별로 나눠 입력하세요 (예: 월급 / 용돈 / 배당금)\n'
          '- 실제 통장에 들어온 금액(세후 기준)을 적는 걸 권장합니다';}
    else if (widget.title.contains('고정 소비')) {
      return '💡 <b>고정 소비란?</b>\n'
          '매달 자동으로 지출되는 고정비용을 말해요. \n'
          '빠질 수 없는 생활비를 입력해주시면 됩니다.\n\n'
          '✍ <b>입력 가이드</b>\n'
          '- 필수적으로 매달 지출되는 항목만 입력하세요 (예: 월세 / 통신비 / 보험료)\n'
          '- 적금과 같은 저축은 고정소비로 생각하지 않아요';
    } else if (widget.title.contains('하루 소비 한도')) {
      return '💡 <b>하루 소비 한도란?</b>\n'
          '- 하루에 얼마만큼 사용할 것인지를 말해요.\n'
          '- 지킬 수 있는 수준에서 정하는 게 좋아요';
    }
    return '';
  }

  String getItemLabel(int index) {
    if (widget.title.contains('월 수입')) return '월 수입처 ${index + 1}';
    if (widget.title.contains('고정 소비')) return '고정소비처 ${index + 1}';
    if (widget.title.contains('하루 소비 한도')) return '하루소비처 ${index + 1}';
    return '항목 ${index + 1}';
  }

  String getCategoryLabel() {
    if (widget.title.contains('월 수입')) return '수입 카테고리';
    if (widget.title.contains('고정 소비')) return '고정 지출 항목';
    if (widget.title.contains('하루 소비 한도')) return '소비 항목';
    return '카테고리';
  }

  Widget buildDescriptionRich() {
    final raw = getDetailDescription();
    if (raw.isEmpty) {
      return const Text('', style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)));
    }

    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>', dotAll: true);
    int last = 0;

    try {
      for (final m in regex.allMatches(raw)) {
        if (m.start > last) spans.add(TextSpan(text: raw.substring(last, m.start)));
        final boldText = m.group(1) ?? '';
        if (boldText.isNotEmpty) {
          spans.add(TextSpan(text: boldText, style: const TextStyle( fontWeight: FontWeight.bold)));
        }
        last = m.end;
      }
      if (last < raw.length) spans.add(TextSpan(text: raw.substring(last)));
    } catch (_) {
      return Text(raw, style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)));
    }

    return Text.rich(TextSpan(children: spans), style: const TextStyle(fontSize: 14, color:Colors.black,));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Item Widget
  // ────────────────────────────────────────────────────────────────────────────
  // Widget buildInputItem(Entry item, int index) {
  //   final categoryController = _categoryControllers[item.idx]!;
  //   final amountController   = _amountControllers[item.idx]!;
  //
  //   // 현재 텍스트 기준 실시간 계산
  //   final String rawDaily = _unformatNumber(amountController.text); // "12,345" -> "12345"
  //   final double daily    = double.tryParse(rawDaily) ?? 0;
  //   final int monthly     = (daily * 30).round(); // 30일 기준
  //
  //   return Container(
  //     key: ValueKey('item_container_${item.idx}'),
  //     margin: const EdgeInsets.only(bottom: 16),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFF9FAFB),
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.15),
  //           blurRadius: 6,
  //         ),
  //       ],
  //     ),
  //     child: Stack(
  //       clipBehavior: Clip.none,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // 카테고리 라벨
  //             SubText(
  //               text: getCategoryLabel(),
  //               fontWeight: FontWeight.bold,
  //               color: AppColors.subText,
  //             ),
  //             const SizedBox(height: 3),
  //
  //             // 카테고리 입력
  //             CustomTextField(
  //               controller: categoryController,
  //               hintText: '(예: 식비/교통비/카페)',
  //               borderRadius: 8,
  //               height: 50,
  //               onChanged: (v) {
  //                 updateItem(item.idx, 'category', v);
  //                 setState(() {});
  //               },
  //             ),
  //             const SizedBox(height: 6),
  //
  //             // 금액 라벨
  //             const SubText(
  //               text: '금액',
  //               fontWeight: FontWeight.bold,
  //               color: AppColors.subText,
  //             ),
  //             const SizedBox(height: 3),
  //
  //             // 금액 입력 (숫자 포맷 실시간 적용)
  //             CustomTextField(
  //               controller: amountController,
  //               hintText: widget.title.contains('하루 소비 한도')
  //                   ? '(예: 10,000)'      // ✅ 하루 소비 한도일 때
  //                   : '(예: 1,000,000)',  // ✅ 고정 수입/고정 소비일 때
  //               keyboardType: TextInputType.number,
  //               borderRadius: 8,
  //               height: 50,
  //               onChanged: (value) {
  //                 final un  = _unformatNumber(value);
  //                 final amt = double.tryParse(un) ?? 0;
  //                 updateItem(item.idx, 'amount', amt);
  //
  //                 // 쉼표 포맷 유지
  //                 final formatted = _formatNumber(un);
  //                 if (formatted != value) {
  //                   amountController.value = TextEditingValue(
  //                     text: formatted,
  //                     selection: TextSelection.collapsed(offset: formatted.length),
  //                   );
  //                 }
  //                 setState(() {});
  //               },
  //             ),
  //             if (widget.title.contains('하루 소비 한도'))
  //               Padding(
  //                 padding: const EdgeInsets.only(top: 3),
  //                 child: Align(
  //                   alignment: Alignment.centerRight,
  //                   child: SubText(
  //                     text: '한 달 ${_formatNumber(monthly.toString())}원 소비',
  //                     fontWeight: FontWeight.bold,
  //                     color: AppColors.primary
  //                   ),
  //                 ),
  //               ),
  //             ],
  //         ),
  //         // X 버튼 (오른쪽 상단)
  //         Positioned(
  //           right: -8,
  //           top: -8,
  //           child: Material(
  //             color: Colors.transparent,
  //             child: InkWell(
  //               onTap: () => removeItem(item.idx),
  //               customBorder: const CircleBorder(),
  //               child: Container(
  //                 width: 36,
  //                 height: 36,
  //                 decoration: const BoxDecoration(
  //                   color: Colors.transparent,
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(
  //                   Icons.close,
  //                   size: 18,
  //                   color: Color(0xFF6B7280),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget buildInputItem(Entry item, int index) {
    final categoryController = _categoryControllers[item.idx]!;
    final amountController   = _amountControllers[item.idx]!;

    // 현재 텍스트 기준 실시간 계산
    final String rawDaily = _unformatNumber(amountController.text);
    final double daily    = double.tryParse(rawDaily) ?? 0;
    final int monthly     = (daily * 30).round();

    return Container(
      key: ValueKey('item_container_${item.idx}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ───── 첫 줄 : 카테고리 + 금액 ─────
          Row(
            children: [
              // 카테고리 입력 (원형 버튼)
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final controller = TextEditingController(text: categoryController.text);
                        return AlertDialog(
                          title: const Text('카테고리 입력'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(hintText: '카테고리명 입력'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, controller.text),
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );

                    if (result != null && result.trim().isNotEmpty) {
                      categoryController.text = result.trim();
                      updateItem(item.idx, 'category', result.trim());
                      setState(() {});
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: categoryController.text.isEmpty
                          ? AppColors.greyBackground     // 입력 전 → 회색
                          : AppColors.lightBlue,   // 입력 후 → 연파랑
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      categoryController.text.isEmpty
                          ? '식비' // 힌트
                          : categoryController.text, // 입력된 값
                      style: TextStyle(
                        fontSize: 12,
                        color: categoryController.text.isEmpty
                            ? Colors.black54 // 힌트 → 연한 회색
                            : Colors.black,  // 입력값 → 진한 검은색
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 금액 입력
              Expanded(
                flex: 4,
                child: CustomTextField(
                  controller: amountController,
                  hintText: widget.title.contains('하루 소비 한도')
                      ? '(예: 10,000)'
                      : '(예: 1,000,000)',
                  keyboardType: TextInputType.number,
                  borderRadius: 8,
                  height: 60,
                  onChanged: (value) {
                    final un  = _unformatNumber(value);
                    final amt = double.tryParse(un) ?? 0;
                    updateItem(item.idx, 'amount', amt);

                    final formatted = _formatNumber(un);
                    if (formatted != value) {
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          // ───── 두 번째 줄 : 서브텍스트 ─────
          if (widget.title.contains('하루 소비 한도'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: SubText(
                  text: '한 달 ${_formatNumber(monthly.toString())}원 소비',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }


  // ────────────────────────────────────────────────────────────────────────────
  // Content / Header / Footer
  // ────────────────────────────────────────────────────────────────────────────
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14)),
            ),
          ...items.asMap().entries.map((e) => buildInputItem(e.value, e.key)),
          SmallRoundedButton(
            text: '항목 추가',
            onPressed: addItem,
            icon: Icons.add,
            backgroundColor: Colors.white,
            textColor: AppColors.subText,
          )
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Visibility(
      visible: !_isKeyboardVisible,
      // child: CustomAppBar(title: widget.title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget buildDetailBox() {
    return Visibility(
      visible: !_isKeyboardVisible,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: buildDescriptionRich(),
        ),
      ),
    );
  }

  Widget buildFooter() {
    if (widget.title.contains('하루 소비 한도')) {
      return _buildFooterDailyLimit();
    } else {
      return _buildFooterDefault();
    }
  }

  Widget _buildFooterDailyLimit() {
    final total = getTotalAmount(); // 일일 합계
    final monthly = (total * 30).toInt();

    // TODO: 실제 계산 결과로 바꾸세요
    final targetDate = DateTime(2026, 5, 23);
    final targetText = DateFormat('yyyy년 M월 d일').format(targetDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all( // 🔥 상단+하단 모두 라운드
          Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ParagraphText(
                          text: '${NumberFormat('#,###').format(total.toInt())}원',
                          fontWeight: FontWeight.bold,
                        ),
                        SubText(text: '일일 총합', fontWeight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 36,
                color: AppColors.greyBackground
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.date_range_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ParagraphText(
                          text: '${NumberFormat('#,###').format(monthly)}원',
                          fontWeight: FontWeight.bold,
                        ),
                        SubText(text: '월별 총합(30일 기준)', fontWeight: FontWeight.bold),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1, // 두께
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                SubText(
                  text: '목표 도달일: $targetText 예정입니다.',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildFooterDefault() {
    final total = getTotalAmount();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: const Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: const BorderRadius.all( // 🔥 상단+하단 모두 라운드
          Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ParagraphText(text: '총합:', fontWeight: FontWeight.bold),
              ParagraphText(
                text: '${NumberFormat('#,###').format(total.toInt())}원',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: handleComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0062FF),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const ParagraphText(
          text: '완료',
          color: AppColors.whiteText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }



  // ────────────────────────────────────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final maxH = MediaQuery.of(context).size.height * 0.9;
    final maxW = MediaQuery.of(context).size.width * 0.9;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildHeader(),
              buildDetailBox(),
              if (!_isKeyboardVisible) const SizedBox(height: 8),
              Expanded(child: buildContent()),
              buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
