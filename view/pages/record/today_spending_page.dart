import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_number_field.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/buttons/select_button.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class TodaySpendingPage extends StatefulWidget {
  const TodaySpendingPage({super.key});

  @override
  State<TodaySpendingPage> createState() => _TodaySpendingPageState();
}

class _TodaySpendingPageState extends State<TodaySpendingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 샘플 데이터
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

  // 감정 데이터
  final Map<String, dynamic> emotionData = {
    'emotion': '기쁨',
    'lottieFile': 'assets/animations/Great.json',
    'diary':
        '오늘 점심에 맛있는 음식을 먹어서 기분이 좋았어요! 하지만 조금 과소비한 것 같아서 내일은 더 신중하게 소비해야겠어요.',
  };

  // 하루 소비 한도 금액 (예시: 9,000원)
  final int dailySpendingLimit = 9000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get totalAmount =>
      spendingItems.fold(0, (sum, item) => sum + item.amount);

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '소비 등록',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 카테고리 선택
                    SelectButton(
                      value: selectedCategory,
                      items: ['식비', '교통비', '문화비', '여가비', '기타'],
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val;
                        });
                      },
                      hintText: '카테고리 선택',
                    ),
                    const SizedBox(height: 16),

                    // 금액 입력
                    CustomNumberField(
                      controller: amountController,
                      hintText: '예: 20,000',
                      backgroundColor: const Color(0xFFF3F4F6),
                      borderRadius: 12,
                      height: 56,
                      suffix: '₩',
                      onChanged: (value) {
                        setState(() {
                          final text = value.replaceAll(',', '');
                          isValidInput =
                              text.isNotEmpty &&
                              int.tryParse(text) != null &&
                              selectedCategory != null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 노트 입력
                    CustomTextField(
                      controller: noteController,
                      hintText: '노트 작성 (20자 이내)',
                      onChanged: (text) {
                        if (text.length > 20) {
                          noteController.text = text.substring(0, 20);
                          noteController.selection = TextSelection.fromPosition(
                            TextPosition(offset: noteController.text.length),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isValidInput
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
                  child: const Text(
                    '등록',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditSpendingDialog(SpendingItem item) {
    String? selectedCategory = item.category;
    final amountController = TextEditingController(
      text: item.amount.toString(),
    );
    final noteController = TextEditingController(text: item.description);
    bool isValidInput = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '소비 수정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 카테고리 선택
                    SelectButton(
                      value: selectedCategory,
                      items: ['식비', '교통비', '문화비', '여가비', '기타'],
                      onChanged: (val) {
                        setState(() {
                          selectedCategory = val;
                        });
                      },
                      hintText: '카테고리 선택',
                    ),
                    const SizedBox(height: 16),

                    // 금액 입력
                    CustomNumberField(
                      controller: amountController,
                      hintText: '예: 20,000',
                      backgroundColor: const Color(0xFFF3F4F6),
                      borderRadius: 12,
                      height: 56,
                      suffix: '₩',
                      onChanged: (value) {
                        setState(() {
                          final text = value.replaceAll(',', '');
                          isValidInput =
                              text.isNotEmpty &&
                              int.tryParse(text) != null &&
                              selectedCategory != null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 노트 입력
                    CustomTextField(
                      controller: noteController,
                      hintText: '노트 작성 (20자 이내)',
                      onChanged: (text) {
                        if (text.length > 20) {
                          noteController.text = text.substring(0, 20);
                          noteController.selection = TextSelection.fromPosition(
                            TextPosition(offset: noteController.text.length),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isValidInput
                      ? () {
                          final amount =
                              int.tryParse(
                                amountController.text.replaceAll(',', ''),
                              ) ??
                              0;

                          // 메인 페이지의 상태 업데이트
                          this.setState(() {
                            final index = spendingItems.indexWhere(
                              (element) => element.id == item.id,
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
                        }
                      : null,
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditEmotionDialog() {
    String? selectedEmotion = emotionData['emotion'];
    final diaryController = TextEditingController(text: emotionData['diary']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '감정 및 소비일지 수정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 감정 선택
                    SelectButton(
                      value: selectedEmotion,
                      items: ['기쁨', '슬픔', '화남', '짜증', '평온', '스트레스'],
                      onChanged: (val) {
                        setState(() {
                          selectedEmotion = val;
                        });
                      },
                      hintText: '감정 선택',
                    ),
                    const SizedBox(height: 16),

                    // 소비일지 입력
                    CustomTextField(
                      controller: diaryController,
                      hintText: '오늘의 소비일지를 작성해주세요',
                      onChanged: (text) {
                        if (text.length > 100) {
                          diaryController.text = text.substring(0, 100);
                          diaryController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: diaryController.text.length),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    // 메인 페이지의 상태 업데이트
                    this.setState(() {
                      emotionData['emotion'] = selectedEmotion;
                      emotionData['diary'] = diaryController.text;
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

            // 탭바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                ),
                child: Stack(
                  children: [
                    // 슬라이드하는 indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _tabController.index == 0
                          ? 2
                          : MediaQuery.of(context).size.width * 0.5 - 2,
                      top: 2,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5 - 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 탭 버튼들
                    Row(
                      children: [
                        // 소비 리스트 탭
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabController.animateTo(0);
                            },
                            child: Container(
                              height: 44,
                              child: Center(
                                child: Text(
                                  '소비 리스트',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: _tabController.index == 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 소비일지 탭
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabController.animateTo(1);
                            },
                            child: Container(
                              height: 44,
                              child: Center(
                                child: Text(
                                  '소비일지',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: _tabController.index == 1
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 탭뷰 콘텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 소비 리스트 탭
                  _buildSpendingListTab(),

                  // 소비일지 탭
                  _buildDiaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingListTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 소비 상세 컨테이너
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
                // 소비 항목들
                spendingItems.isEmpty
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
                              '등록된 소비가 없어요',
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
                        children: spendingItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Column(
                            children: [
                              _buildSpendingItemWithSwipe(item),
                              // 마지막 항목이 아니면 점선 추가
                              if (index < spendingItems.length - 1)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  height: 1,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.red.withOpacity(0.3),
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

                // 구분선과 합계 (소비 항목이 있을 때만 표시)
                if (spendingItems.isNotEmpty) ...[
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
                                    ? const Color(0xFFEF9A9A) // 빨간색 테두리 (초과 시)
                                    : const Color(0xFF4A90E2), // 파란색 테두리 (절약 시)
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

          const SizedBox(height: 24),

          // 소비내역 추가 버튼
          GestureDetector(
            onTap: _showAddSpendingDialog,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: DashedBorderPainter(),
                child: const Center(
                  child: Text(
                    '소비내역 추가 +',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
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

  Widget _buildDiaryTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 감정 및 소비일지 컨테이너
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 편집 아이콘
                  Row(
                    children: [
                      Text(
                        '오늘의 감정',
                        style: TextStyle(
                          fontSize: 18,
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
                            child: Icon(
                              Icons.edit,
                              color: Color(0xFF9E9E9E),
                              size: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Lottie 애니메이션과 감정명
                  Center(
                    child: Column(
                      children: [
                        // Lottie 애니메이션
                        Container(
                          width: 120,
                          height: 120,
                          child: Lottie.asset(
                            emotionData['lottieFile'],
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 감정명
                        Text(
                          '😊 ${emotionData['emotion']}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 소비일지
                  Text(
                    '소비일지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Text(
                      emotionData['diary'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingItemWithSwipe(SpendingItem item) {
    return Dismissible(
      key: Key('spending_item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: const BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.only(
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
      child: _buildSpendingItem(item),
    );
  }

  Widget _buildSpendingItem(SpendingItem item) {
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

              // 금액 (조건에 따라 색상 변경)
              Text(
                '${_formatAmount(item.amount)}원',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: totalAmount > dailySpendingLimit
                      ? const Color(0xFFE53E3E) // 빨간색 (초과 시)
                      : const Color(0xFF3182CE), // 파란색 (한도 내)
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

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    const radius = 12.0;

    // 점선 그리기
    _drawDashedRect(canvas, size, paint, dashWidth, dashSpace, radius);
  }

  void _drawDashedRect(
    Canvas canvas,
    Size size,
    Paint paint,
    double dashWidth,
    double dashSpace,
    double radius,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final length = pathMetrics.length;

    double distance = 0;
    bool draw = true;

    while (distance < length) {
      final start = distance;
      final end = draw
          ? (distance + dashWidth).clamp(0.0, length)
          : (distance + dashSpace).clamp(0.0, length);

      if (draw) {
        final tangent = pathMetrics.getTangentForOffset(start);
        if (tangent != null) {
          final startPoint = tangent.position;
          final endPoint =
              pathMetrics.getTangentForOffset(end)?.position ?? startPoint;
          canvas.drawLine(startPoint, endPoint, paint);
        }
      }

      distance = end.toDouble();
      draw = !draw;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
