import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:sotong_local/component/appbars/custom_app_bar.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/texts/subtext.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';

import '../../../../../component/buttons/small_rounded_button.dart';
import '../../../../../component/texts/header_text.dart';

import '../../../../../component/theme/app_spacing.dart';
import 'input_item_daily.dart';
import 'input_item_basic.dart';
import 'footer_daily.dart';
import 'footer_default.dart';
import 'category_utils.dart';

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
    this.placeholder = '수입 카테고리',
    this.hintText = '예: 월급, 아르바이트, 용돈 등',
    this.initialEntries,
  }) : super(key: key);

  @override
  State<InputModalWidget> createState() => _InputModalWidgetState();
}

class _InputModalWidgetState extends State<InputModalWidget> {
  List<Entry> items = [];
  String error = '';

  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _categoryControllers = {};

  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _isKeyboardVisible = false;

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
    final isDaily = widget.title.contains('하루 사용 금액');

    // 기본 생성 개수: 일일 소비는 1칸, 나머지는 3칸
    final int minCount = isDaily ? 1 : 3;
    // 만약 "일일 소비도 3칸" 원하시면 위 줄을: final int minCount = 3; 로 바꾸세요.

    if (initial != null && initial.isNotEmpty) {
      // 1) 전달된 초기 데이터 적용
      items = List<Entry>.from(initial);

      // 2) 컨트롤러 초기화
      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }

      // 3) 3칸(또는 1칸) 미만이면 빈 항목으로 패딩
      while (items.length < minCount) {
        final seed = Entry(
          idx: DateTime.now().millisecondsSinceEpoch + items.length,
          amount: 0,
          category: '',
          type: widget.type,
        );
        items.add(seed);
        _initializeControllers(seed.idx, seed.category, seed.amount);
      }
    } else {
      // 초기 데이터가 없으면 기본 minCount만큼 생성
      items = List.generate(minCount, (i) {
        return Entry(
          idx: DateTime.now().millisecondsSinceEpoch + i,
          amount: 0,
          category: '',
          type: widget.type,
        );
      });

      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _amountControllers.values) c.dispose();
    for (final c in _categoryControllers.values) c.dispose();
    super.dispose();
  }

  void _initializeControllers(int idx, String category, double amount) {
    _categoryControllers[idx] = TextEditingController(text: category);
    _amountControllers[idx] = TextEditingController(
      text: amount > 0 ? _formatNumber(amount.toStringAsFixed(0)) : '',
    );
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

    setState(() {
      if (error.isNotEmpty) error = '';
    });
  }

  void removeItem(int idx) {
    setState(() {
      items.removeWhere((e) => e.idx == idx);
      _categoryControllers[idx]?.dispose();
      _amountControllers[idx]?.dispose();
      _categoryControllers.remove(idx);
      _amountControllers.remove(idx);
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

  // String getDetailDescription() {
  //   if (widget.title.contains('월 수입')) {
  //     return '💡 <b>월 수입이란?</b>\n'
  //         '- 매달 반복적으로 들어오는 수입\n'
  //         '- 금액이 일정치 않다면 최근 3개월 평균 입력\n\n'
  //         '✍ <b>입력 가이드</b>\n'
  //         '- 수입이 여러 가지라면 항목별로 입력\n'
  //         '- 실제 통장에 들어온 세후 금액 기준으로 입력';
  //   } else if (widget.title.contains('고정 소비')) {
  //     return '💡 <b>고정 소비란?</b>\n'
  //         '매달 빠짐없이 자동으로 지출되는 비용 \n\n'
  //         '✍ <b>입력 가이드</b>\n'
  //         '- 필수 지출 항목만 입력\n'
  //         '- 저축·투자는 제외';
  //   } else if (widget.title.contains('하루 사용 금액')) {
  //     return '💡 <b>하루 사용 금액이란?</b>\n'
  //         '- 평균적으로 매일 쓰는 생활비 기준\n\n'
  //         '✍ <b>입력 가이드</b>\n'
  //         '- 유지 가능한 수준에서 입력\n'
  //         '- 원 단위로 입력';
  //   }
  //   return '';
  // }

  // Widget buildDescriptionRich() {
  //   final raw = getDetailDescription();
  //   if (raw.isEmpty) return const SizedBox.shrink();
  //   final spans = <TextSpan>[];
  //   final regex = RegExp(r'<b>(.*?)</b>', dotAll: true);
  //   int last = 0;
  //   for (final m in regex.allMatches(raw)) {
  //     if (m.start > last) spans.add(TextSpan(text: raw.substring(last, m.start)));
  //     final boldText = m.group(1) ?? '';
  //     spans.add(TextSpan(
  //         text: boldText, style: const TextStyle(fontWeight: FontWeight.bold)));
  //     last = m.end;
  //   }
  //   if (last < raw.length) spans.add(TextSpan(text: raw.substring(last)));
  //   return Text.rich(TextSpan(children: spans),
  //       style: const TextStyle(fontSize: 14, color: Colors.black));
  // }

  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          if (error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(error,
                  style:
                  const TextStyle(color: Color(0xFFDC2626), fontSize: 14)),
            ),
          ...items.asMap().entries.map((e) {
            final idx = e.key;
            final item = e.value;

            if (widget.title.contains('하루 사용 금액')) {
              return InputItemDaily(
                item: item,
                categoryController: _categoryControllers[item.idx]!,
                amountController: _amountControllers[item.idx]!,
                onUpdate: updateItem,
                onRemove: removeItem,
                index: idx,
              );
            } else {
              return InputItemBasic(
                item: item,
                categoryController: _categoryControllers[item.idx]!,
                amountController: _amountControllers[item.idx]!,
                placeholder: widget.placeholder,
                onUpdate: updateItem,
                onRemove: removeItem,
                index: idx,
              );
            }
          }).toList(),
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

  Widget buildDetailBox() {
    // 타입/타이틀에 따라 문구 바꿔서 쓰고 싶으면 여기서 분기해도 됨
    String titleText = '변동 가능성이 있는\n소비를 입력해주세요';
    String captionText = '지출 금액을 조절할 수 있는 항목(소비)를 의미해요.';

    if (widget.title.contains('월 수입')) {
      titleText = '월 수입을 입력해주세요';
      captionText = '매달 반복적으로 들어오는 수입을 항목별로 입력해요.';
    } else if (widget.title.contains('고정 소비')) {
      titleText = '고정 소비를 입력해주세요';
      captionText = '매달 빠짐없이 자동으로 지출되는 비용만 입력해요.';
    } else if (widget.title.contains('하루 사용 금액')) {
      titleText = '변동 가능성이 있는\n소비를 입력해주세요';
      captionText = '매일 평균적으로 쓰는 생활비예요.';
    }

    return Visibility(
      visible: !_isKeyboardVisible,
      child: Column(
          children: [
            SizedBox(height: 100), // 나중에는 픽셀로 하지말고 비율로 위 아래 공간 확보
            // CustomAppBar(title:'', onBack: () => Navigator.of(context).pushReplacementNamed('/chat_plan'),),
            // 타이틀/서브설명
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderText(text: titleText),
                  const SizedBox(height: 10),
                  _CaptionWithDot(text: captionText),
                ],
              ),
            ),
          ]
      ),
    );
  }



  Widget buildFooter() {
    if (widget.title.contains('하루 사용 금액')) {
      return FooterDaily(total: getTotalAmount(), onComplete: handleComplete);
    } else {
      return FooterDefault(total: getTotalAmount(), onComplete: handleComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final maxH = MediaQuery.of(context).size.height * 0.9;
    final maxW = MediaQuery.of(context).size.width * 0.9;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          // padding: const EdgeInsets.all(20),
          // margin: const EdgeInsets.all(16),
          // constraints: BoxConstraints(maxHeight: maxH, maxWidth: maxW),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: const BoxDecoration(
              //     border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Text(widget.title,
              //           style: const TextStyle(
              //               fontSize: 18, fontWeight: FontWeight.bold)),
              //     ],
              //   ),
              // ),
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
