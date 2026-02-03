import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/inputs/spending_entry_row.dart';
import 'package:sotong_local/component/buttons/select_button.dart';
import 'package:sotong_local/component/buttons/period_toggle.dart';
import 'package:sotong_local/component/buttons/custom_dual_button.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:lottie/lottie.dart';

class TodaySpendingTestPage extends StatefulWidget {
  const TodaySpendingTestPage({super.key});

  @override
  State<TodaySpendingTestPage> createState() => _TodaySpendingTestPageState();
}

class _TodaySpendingTestPageState extends State<TodaySpendingTestPage> {
  bool _showDiaryModal = false;
  bool isWeekly = true; // 수입/소비 토글 (true: 수입, false: 소비)
  bool isList = true; // 목록/일지 토글 (true: 목록, false: 일지)

  // 샘플 데이터 - 소비
  List<SpendingItem> spendingItems = [
    SpendingItem(
      id: '1',
      category: '식비',
      categoryColor: const Color(0xFF9E9E9E),
      description: '점심식사',
      amount: 7000,
    ),
    SpendingItem(
      id: '2',
      category: '교통비',
      categoryColor: const Color(0xFF9E9E9E),
      description: '영화',
      amount: 2900,
    ),
  ];

  // 샘플 데이터 - 수입
  List<SpendingItem> incomeItems = [
    SpendingItem(
      id: 'i1',
      category: '급여',
      categoryColor: const Color(0xFF9E9E9E),
      description: '월급',
      amount: 3000000,
    ),
    SpendingItem(
      id: 'i2',
      category: '부수입',
      categoryColor: const Color(0xFF9E9E9E),
      description: '용돈',
      amount: 50000,
    ),
  ];

  // 감정 데이터
  final Map<String, dynamic> emotionData = {
    'emotion': '기쁨',
    'lottieFile': 'assets/animations/Great.json',
    'diary':
    '오늘 점심에 맛있는 음식을 먹어서 기분이 좋았어요! 하지만 조금 과소비한 것 같아서 내일은 더 신중하게 소비해야겠어요.',
  };

  // 하루 소비 한도 금액 (예시: 9,000원)
  final int dailySpendingLimit = 9000;

  int get totalAmount => isWeekly
      ? incomeItems.fold(0, (sum, item) => sum + item.amount)
      : spendingItems.fold(0, (sum, item) => sum + item.amount);

  List<SpendingItem> get currentItems => isWeekly ? incomeItems : spendingItems;

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
    );
  }

  // 차액 계산 (오늘 소비 - 하루 한도)
  int get differenceAmount => totalAmount - dailySpendingLimit;

  // 시간 환산 (1분당 0.11원 기준)
  int get timeInMinutes {
    if (differenceAmount <= 0) return 0;
    return (differenceAmount / 0.11).round();
  }

  // 시간을 시:분 형태로 변환
  String _formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}시간';
      } else {
        return '${hours}시간 ${remainingMinutes}분';
      }
    }
  }

  void _showAddSpendingDialog() {
    String? selectedCategory;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isValidInput = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              '소비 기록하기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // 균형을 위한 빈 공간
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 날짜 표시
                    Center(
                      child: Text(
                        '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SpendingEntryRow(
                      categoryLabel: selectedCategory,
                      onCategoryTap: () {
                        _showCategoryPickerModal(
                          context: context,
                          current: selectedCategory,
                          onSelected: (val) {
                            setState(() {
                              selectedCategory = val;
                              final text = amountController.text.replaceAll(
                                ',',
                                '',
                              );
                              isValidInput =
                                  text.isNotEmpty &&
                                      int.tryParse(text) != null &&
                                      selectedCategory != null;
                            });
                          },
                        );
                      },
                      amountController: amountController,
                      noteController: noteController,
                      onAmountChanged: (value) {
                        setState(() {
                          final text = value.replaceAll(',', '');
                          isValidInput =
                              text.isNotEmpty &&
                                  int.tryParse(text) != null &&
                                  selectedCategory != null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 추가 버튼
                    GestureDetector(
                      onTap: isValidInput
                          ? () {
                        final amount =
                            int.tryParse(
                              amountController.text.replaceAll(',', ''),
                            ) ??
                                0;
                        final newItem = SpendingItem(
                          id: DateTime.now().millisecondsSinceEpoch
                              .toString(),
                          category: selectedCategory!,
                          categoryColor: const Color(0xFF9E9E9E),
                          description: noteController.text.isEmpty
                              ? selectedCategory!
                              : noteController.text,
                          amount: amount,
                        );

                        // 메인 페이지의 상태 업데이트
                        this.setState(() {
                          spendingItems.add(newItem);
                        });

                        Navigator.of(context).pop();
                      }
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isValidInput
                              ? const Color(0xFF4A90E2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              color: isValidInput
                                  ? Colors.white
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '추가',
                              style: TextStyle(
                                fontSize: 16,
                                color: isValidInput
                                    ? Colors.white
                                    : Colors.grey[600],
                                fontWeight: FontWeight.bold,
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
          },
        );
      },
    );
  }

  static const List<String> _categoryOptions = [
    '식비',
    '교통비',
    '문화비',
    '여가비',
    '급여',
    '부수입',
    '기타',
  ];

  void _showCategoryPickerModal({
    required BuildContext context,
    required String? current,
    required void Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.45;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    '카테고리 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _categoryOptions
                          .map(
                            (category) => InkWell(
                          onTap: () {
                            onSelected(category);
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: current == category
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSpendingDialog(SpendingItem item) {
    String? selectedCategory = item.category;
    final amountController = TextEditingController(
      text: _formatAmount(item.amount),
    );
    final noteController = TextEditingController(text: item.description);
    bool isValidInput = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final modalHeight = MediaQuery.of(context).size.height * 0.8;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: modalHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '소비 수정',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SpendingEntryRow(
                                    categoryLabel: selectedCategory,
                                    onCategoryTap: () {
                                      _showCategoryPickerModal(
                                        context: context,
                                        current: selectedCategory,
                                        onSelected: (val) {
                                          setModalState(() {
                                            selectedCategory = val;
                                            final text = amountController.text
                                                .replaceAll(',', '');
                                            isValidInput =
                                                text.isNotEmpty &&
                                                    int.tryParse(text) != null &&
                                                    selectedCategory != null;
                                          });
                                        },
                                      );
                                    },
                                    amountController: amountController,
                                    noteController: noteController,
                                    amountSuffix: '원',
                                    greyBackgroundOnly: true,
                                    onAmountChanged: (value) {
                                      setModalState(() {
                                        final text = value.replaceAll(',', '');
                                        isValidInput =
                                            text.isNotEmpty &&
                                                int.tryParse(text) != null &&
                                                selectedCategory != null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: CustomButton(
                            text: '수정',
                            onPressed: () {
                              if (!isValidInput) return;
                              final amount =
                                  int.tryParse(
                                    amountController.text.replaceAll(',', ''),
                                  ) ??
                                      0;
                              setState(() {
                                final index = spendingItems.indexWhere(
                                      (e) => e.id == item.id,
                                );
                                if (index != -1) {
                                  spendingItems[index] = SpendingItem(
                                    id: item.id,
                                    category: selectedCategory!,
                                    categoryColor: const Color(0xFF9E9E9E),
                                    description: noteController.text.isEmpty
                                        ? selectedCategory!
                                        : noteController.text,
                                    amount: amount,
                                  );
                                }
                              });
                              Navigator.of(context).pop();
                            },
                            enabled: isValidInput,
                            height: 56,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditEmotionDialog() {
    String? selectedEmotion = emotionData['emotion'];
    final diaryController = TextEditingController(text: emotionData['diary']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '감정 및 소비일지 수정',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SelectButton(
                          value: selectedEmotion,
                          items: ['기쁨', '슬픔', '화남', '짜증', '평온', '스트레스'],
                          onChanged: (val) {
                            setModalState(() => selectedEmotion = val);
                          },
                          hintText: '감정 선택',
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: diaryController,
                          hintText: '오늘의 소비일지를 작성해주세요',
                          onChanged: (text) {
                            if (text.length > 100) {
                              diaryController.text = text.substring(0, 100);
                              diaryController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: diaryController.text.length,
                                    ),
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        CustomDualButton(
                          leftLabel: '취소',
                          rightLabel: '수정',
                          onLeftPressed: () => Navigator.of(context).pop(),
                          onRightPressed: () {
                            setState(() {
                              emotionData['emotion'] = selectedEmotion;
                              emotionData['diary'] = diaryController.text;
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // 헤더
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            '오늘의 소비',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // 균형을 위한 빈 공간
                    ],
                  ),
                ),

                // 수입/소비 토글 (레포트·소통과 동일: width 120, height 34)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TwoOptionToggle(
                        labels: const ['수입', '소비'],
                        selected: isWeekly ? '수입' : '소비',
                        onChanged: (v) => setState(() => isWeekly = v == '수입'),
                        width: 120,
                        height: 34,
                      ),
                    ],
                  ),
                ),

                // 소비 선택 시 목록/일지 토글 (레포트·소통과 동일: width 120, height 34)
                if (!isWeekly) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TwoOptionToggle(
                          labels: const ['목록', '일지'],
                          selected: isList ? '목록' : '일지',
                          onChanged: (v) => setState(() => isList = v == '목록'),
                          width: 120,
                          height: 34,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 콘텐츠
                Expanded(child: _buildSpendingListTab()),

                // 하단 소비내역 추가 버튼
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: GestureDetector(
                    onTap: _showAddSpendingDialog,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isWeekly ? '수입 입력하기' : '소비 입력하기',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 소비일지 모달
          if (_showDiaryModal)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDiaryModal = false;
                });
              },
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // 모달 내부 클릭 시 닫히지 않도록
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      constraints: const BoxConstraints(maxHeight: 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 헤더
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Text(
                                  '소비일지',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _showDiaryModal = false;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.black87,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          // 소비일지 내용
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _buildDiaryContent(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 편집 아이콘
        Row(
          children: [
            Text(
              '오늘의 감정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _showEditEmotionDialog();
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.edit, color: Color(0xFF9E9E9E), size: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lottie 애니메이션과 감정명
        Center(
          child: Column(
            children: [
              // Lottie 애니메이션
              Container(
                width: 80,
                height: 80,
                child: Lottie.asset(
                  emotionData['lottieFile'],
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              // 감정명
              Text(
                '😊 ${emotionData['emotion']}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 소비일지
        Text(
          '소비일지',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Text(
            emotionData['diary'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingListTab() {
    // 소비 - 일지 선택 시 감정과 소비일지 표시
    if (!isWeekly && !isList) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildDiaryContent(),
        ),
      );
    }

    // 수입 또는 소비 - 목록 선택 시 목록 표시
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // 상세 컨테이너
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 항목들 (수입/소비에 따라 변경)
                  currentItems.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isWeekly ? '등록된 수입이 없어요' : '등록된 소비가 없어요',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Column(
                    children: currentItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _buildSpendingItemWithSwipe(item, isWeekly),
                          // 마지막 항목이 아니면 점선 추가
                          if (index < currentItems.length - 1)
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              height: 1,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: isWeekly
                                        ? Colors.black26
                                        : Colors.red.withOpacity(0.3),
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),

                  // 구분선과 합계 (항목이 있을 때만 표시, 소비일 때만)
                  if (currentItems.isNotEmpty && !isWeekly) ...[
                    Container(
                      height: 1,
                      color: const Color(0xFFE0E0E0),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),

                    // 합계 및 차액 정보
                    Container(
                      decoration: BoxDecoration(
                        color: differenceAmount > 0
                            ? const Color(0xFFFFEBEE) // 분홍색 (초과 시)
                            : const Color(0xFFF8FBFF), // 연하늘색 (한도 내)
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 오늘의 소비
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '오늘의 소비',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${_formatAmount(totalAmount)}원',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: differenceAmount > 0
                                      ? const Color(0xFFE53935) // 빨간색 (초과 시)
                                      : const Color(0xFF4A90E2), // 파란색 (한도 내)
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 하루 소비 한도
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '하루소비한도금액',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '${_formatAmount(dailySpendingLimit)}원',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 차액
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '차액',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${_formatAmount(differenceAmount)}원',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: differenceAmount > 0
                                      ? Colors.red
                                      : const Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),

                          // 시간 환산 메시지 (단순화)
                          if (differenceAmount != 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: differenceAmount > 0
                                    ? const Color(0xFFFFEBEE) // 빨간색 배경 (초과 시)
                                    : const Color(0xFFE3F2FD), // 파란색 배경 (절약 시)
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: differenceAmount > 0
                                      ? const Color(
                                    0xFFEF9A9A,
                                  ) // 빨간색 테두리 (초과 시)
                                      : const Color(
                                    0xFF4A90E2,
                                  ), // 파란색 테두리 (절약 시)
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: differenceAmount > 0
                                        ? const Color(0xFFE53935) // 빨간색 (초과 시)
                                        : const Color(0xFF4A90E2), // 파란색 (절약 시)
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      differenceAmount > 0
                                          ? '${_formatAmount(differenceAmount)}원치, 목표도달까지 ${_formatTime(timeInMinutes)}이 미뤄졌어요! 내일 더 힘내봐요!'
                                          : '${_formatAmount(differenceAmount.abs())}원치, 목표도달까지 ${_formatTime(timeInMinutes.abs())}이 당겨졌어요! 오늘도 잘했어요!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: differenceAmount > 0
                                            ? const Color(
                                          0xFFE53935,
                                        ) // 빨간색 (초과 시)
                                            : const Color(
                                          0xFF4A90E2,
                                        ), // 파란색 (절약 시)
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingItemWithSwipe(SpendingItem item, bool isWeekly) {
    final deleteBgColor = isWeekly ? Colors.black54 : Colors.red;
    return Dismissible(
      key: Key('spending_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: deleteBgColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        setState(() {
          spendingItems.removeWhere((element) => element.id == item.id);
        });
      },
      child: _buildSpendingItem(item, isWeekly),
    );
  }

  Widget _buildSpendingItem(SpendingItem item, bool isWeekly) {
    final amountColor = isWeekly
        ? Colors.black87
        : (totalAmount > dailySpendingLimit
        ? const Color(0xFFE53E3E) // 빨간색 (초과 시)
        : const Color(0xFF3182CE)); // 파란색 (한도 내)
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 태그
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0), // 연한 회색
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.category,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 노트와 금액을 같은 줄에 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 노트와 편집 아이콘
              Row(
                children: [
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showEditSpendingDialog(item),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.edit,
                          color: Color(0xFF999999),
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 금액 (수입창은 검정, 소비창은 한도에 따라 빨강/파랑)
              Text(
                '${_formatAmount(item.amount)}원',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpendingItem {
  final String id;
  final String category;
  final Color categoryColor;
  final String description;
  final int amount;

  SpendingItem({
    required this.id,
    required this.category,
    required this.categoryColor,
    required this.description,
    required this.amount,
  });
}
