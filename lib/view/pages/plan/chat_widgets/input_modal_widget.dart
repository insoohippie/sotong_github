import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';

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
    this.placeholder = "카테고리명",
    this.hintText = "예: 월급, 아르바이트, 용돈 등",
    this.initialEntries,
  }) : super(key: key);

  @override
  State<InputModalWidget> createState() => _InputModalWidgetState();
}

class _InputModalWidgetState extends State<InputModalWidget> {
  List<Entry> items = [];
  String error = '';

  // 각 폼 컨트롤러
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, TextEditingController> _categoryControllers = {};
  final Map<int, FocusNode> _categoryFocusNodes = {};
  final Map<int, FocusNode> _amountFocusNodes = {};

  // 키보드 감지는 플러그인만 사용
  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();

    // 키보드 상태 감지 - 플러그인만 사용
    _keyboardVisibilityController = KeyboardVisibilityController();
    _checkInitialKeyboardState();

    _keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });

    // 기존 데이터 초기화
    if (widget.initialEntries != null && widget.initialEntries!.isNotEmpty) {
      items = List.from(widget.initialEntries!);
      for (final item in items) {
        _initializeControllers(item.idx, item.category, item.amount);
      }
    } else {
      items = [
        Entry(
          idx: DateTime.now().millisecondsSinceEpoch,
          amount: 0,
          category: '',
          type: widget.type,
        ),
      ];
      final firstItem = items.first;
      _initializeControllers(
        firstItem.idx,
        firstItem.category,
        firstItem.amount,
      );
    }
  }

  void _initializeControllers(int idx, String category, double amount) {
    _categoryControllers[idx] = TextEditingController(text: category);
    _amountControllers[idx] = TextEditingController(
      text: amount > 0 ? _formatNumber(amount.toStringAsFixed(0)) : '',
    );
    _categoryFocusNodes[idx] = FocusNode();
    _amountFocusNodes[idx] = FocusNode();
  }

  Future<void> _checkInitialKeyboardState() async {
    bool isVisible = await _keyboardVisibilityController.isVisible;
    setState(() {
      _isKeyboardVisible = isVisible;
    });
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    for (final focusNode in _categoryFocusNodes.values) {
      focusNode.dispose();
    }
    for (final focusNode in _amountFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _unformatNumber(String value) {
    return value.replaceAll(',', '');
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(_unformatNumber(value));
    if (number == null) return '';
    return NumberFormat('#,###').format(number);
  }

  void addItem() {
    final newIdx = DateTime.now().millisecondsSinceEpoch + items.length;

    setState(() {
      items.add(Entry(idx: newIdx, amount: 0, category: '', type: widget.type));
      _initializeControllers(newIdx, '', 0);
    });
  }

  void updateItem(int idx, String field, dynamic value) {
    final index = items.indexWhere((item) => item.idx == idx);
    if (index != -1) {
      if (field == 'category') {
        items[index].category = value;
      } else if (field == 'amount') {
        items[index].amount = value;
      }

      if (error.isNotEmpty) {
        setState(() {
          error = '';
        });
      }
    }
  }

  void removeItem(int idx) {
    setState(() {
      items.removeWhere((item) => item.idx == idx);
      _categoryControllers[idx]?.dispose();
      _amountControllers[idx]?.dispose();
      _categoryFocusNodes[idx]?.dispose();
      _amountFocusNodes[idx]?.dispose();
      _categoryControllers.remove(idx);
      _amountControllers.remove(idx);
      _categoryFocusNodes.remove(idx);
      _amountFocusNodes.remove(idx);
    });
  }

  double getTotalAmount() {
    return items.fold(0, (sum, item) => sum + item.amount);
  }

  void handleComplete() {
    final validItems = items
        .where((item) => item.category.isNotEmpty && item.amount > 0)
        .toList();
    final hasEmptyCategory = items.any(
      (item) => item.amount > 0 && item.category.trim().isEmpty,
    );

    if (hasEmptyCategory) {
      setState(() {
        error = '카테고리명을 정확히 입력해주세요.';
      });
      return;
    }

    if (validItems.isEmpty) {
      setState(() {
        error = '최소 하나의 항목을 입력해주세요.';
      });
      return;
    }

    widget.onComplete(validItems, getTotalAmount());
    widget.onClose();
    setState(() {
      error = '';
    });
  }

  // 상세 설명 텍스트 생성
  String getDetailDescription() {
    if (widget.title.contains('월 수입')) {
      return '💰 <b>월 수입</b>이란?\n한 달 동안 내가 벌어들이는 <b>총 금액</b>입니다. 급여, 부수입, 용돈 등 모두 포함돼요.\n\n예시: 직장 월급, 아르바이트 수입, 콘텐츠 수익, 가족 용돈, 중고 거래 수입\n\n💡 <b>소통 tip!</b>\n수입이 매달 다르다면 최근 3개월 <b>평균 금액</b>을 입력해주세요.';
    } else if (widget.title.contains('고정 소비')) {
      return '💰 <b>고정 소비</b>란?\n매달 정기적으로 나가는 <b>생활 필수 비용</b>입니다. 수입이 없어도 꼭 나가는 <b>지출</b>이에요.\n\n예시: 월세, 핸드폰 요금, 정기권, 보험료, 대출 상환금\n\n💡 <b>소통 tip!</b>\n예적금이나 투자금은 고정 소비가 아닌 <b>저축 항목</b>으로 따로 분류돼요.';
    } else if (widget.title.contains('하루 소비 한도')) {
      return '💰 <b>하루 소비 한도 금액</b>이란?\n하루 동안 사용할 수 있도록 설정한 <b>최대 지출 금액</b>입니다.\n\n예시: 커피값, 점심값, 편의점 음식, 외식비, 택시비\n\n💡 <b>소통 tip!</b>\n플랜 기간과 목표 금액에 따라 자동 계산되며, 예정된 소비가 많을수록 줄어들 수 있어요.';
    }
    return '';
  }

  // 항목 라벨 생성
  String getItemLabel(int index) {
    if (widget.title.contains('월 수입')) {
      return '월 수입처 ${index + 1}';
    } else if (widget.title.contains('고정 소비')) {
      return '고정소비처 ${index + 1}';
    } else if (widget.title.contains('하루 소비 한도')) {
      return '하루소비처 ${index + 1}';
    }
    return '항목 ${index + 1}';
  }

  // Rich Text 생성
  Widget buildDescriptionRich() {
    final raw = getDetailDescription();

    if (raw.isEmpty) {
      return const Text(
        '',
        style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
      );
    }

    final spans = <TextSpan>[];
    final regex = RegExp(r'<b>(.*?)</b>', dotAll: true);
    int last = 0;

    try {
      for (final match in regex.allMatches(raw)) {
        if (match.start > last) {
          final text = raw.substring(last, match.start);
          if (text.isNotEmpty) {
            spans.add(TextSpan(text: text));
          }
        }
        final boldText = match.group(1) ?? '';
        if (boldText.isNotEmpty) {
          spans.add(
            TextSpan(
              text: boldText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        last = match.end;
      }
      if (last < raw.length) {
        final remainingText = raw.substring(last);
        if (remainingText.isNotEmpty) {
          spans.add(TextSpan(text: remainingText));
        }
      }
    } catch (e) {
      return Text(
        raw,
        style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
    );
  }

  // 공통 입력 항목 위젯 추출
  Widget buildInputItem(Entry item, int index) {
    return Container(
      key: ValueKey('item_container_${item.idx}'),
      // 컨테이너에 고유 키 추가
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getItemLabel(index),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (items.length > 1)
                GestureDetector(
                  onTap: () => removeItem(item.idx),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 카테고리 입력 필드 - Builder 제거
          TextField(
            key: ValueKey('category_${item.idx}'),
            controller: _categoryControllers[item.idx],
            focusNode: _categoryFocusNodes[item.idx],
            decoration: InputDecoration(
              hintText: widget.placeholder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              updateItem(item.idx, 'category', value);
              // 실시간 총합 업데이트를 위해 setState 호출
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          // 금액 입력 필드 - Builder 제거
          TextField(
            key: ValueKey('amount_${item.idx}'),
            controller: _amountControllers[item.idx],
            focusNode: _amountFocusNodes[item.idx],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '금액',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (value) {
              final unformatted = _unformatNumber(value);
              final amount = double.tryParse(unformatted) ?? 0;
              updateItem(item.idx, 'amount', amount);

              // 실시간 총합 업데이트를 위해 setState 호출
              setState(() {});

              // 포커스 유지하면서 포맷팅 적용
              final controller = _amountControllers[item.idx];
              if (controller != null) {
                final formattedText = _formatNumber(unformatted);
                controller.value = TextEditingValue(
                  text: formattedText,
                  selection: TextSelection.collapsed(
                    offset: formattedText.length,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // 공통 콘텐츠 위젯 추출
  Widget buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 에러 메시지
          if (error.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFEF2F2),
                border: Border.all(color: Color(0xFFFECACA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 14),
              ),
            ),
          // 입력 항목들
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return buildInputItem(item, index);
          }),
          // 항목 추가 버튼
          GestureDetector(
            onTap: addItem,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFFD1D5DB),
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 20, color: Color(0xFF6B7280)),
                  SizedBox(width: 8),
                  Text(
                    '항목 추가',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - Visibility로 조건부 표시 (위젯 트리 구조 유지)
              Visibility(
                visible: !_isKeyboardVisible,
                maintainSize: false,
                maintainAnimation: false,
                maintainState: true,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF0F0F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // Detail Description - Visibility로 조건부 표시
              Visibility(
                visible: !_isKeyboardVisible,
                maintainSize: false,
                maintainAnimation: false,
                maintainState: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: buildDescriptionRich(),
                  ),
                ),
              ),

              Visibility(
                visible: !_isKeyboardVisible,
                maintainSize: false,
                maintainAnimation: false,
                maintainState: true,
                child: const SizedBox(height: 8),
              ),

              // Content - 단일 위젯으로 통일 (중복 제거)
              Expanded(child: buildContent()),

              // Footer - 항상 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '총합:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(getTotalAmount().toInt())}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0062FF),
                          ),
                        ),
                      ],
                    ),
                    if (widget.title.contains('하루 소비 한도'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '한달 소비 한도 금액: ${NumberFormat('#,###').format(getTotalAmount() * 30)}원',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: handleComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0062FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '완료',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
