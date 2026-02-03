// lib/view/pages/record/today_spending_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import 'package:sotong_local/component/buttons/period_toggle.dart'; // TwoOptionToggle
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/buttons/custom_dual_button.dart';
import 'package:sotong_local/component/buttons/select_button.dart';
import 'package:sotong_local/component/inputs/spending_entry_row.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

import 'package:sotong_local/model/record/spending_entry.dart';
import 'package:sotong_local/view_model/home/today_spending_view_model.dart';

// ✅ 임시 수입 연결 (플랜용 추가입금 VM)
import 'package:sotong_local/view_model/addIncome/add_income_view_model.dart';
import 'package:sotong_local/model/addIncome/income_entry.dart';

class TodaySpendingPage extends StatefulWidget {
  const TodaySpendingPage({super.key});

  @override
  State<TodaySpendingPage> createState() => _TodaySpendingPageState();
}

class _TodaySpendingPageState extends State<TodaySpendingPage> {
  DateTime? _argDate;

  // 2번 UI의 토글 상태
  bool _isIncome = false; // true: 수입, false: 소비
  bool _isList = true; // (소비일 때만) true: 목록, false: 일지

  static const List<String> _emotionOptions = [
    '기쁨',
    '슬픔',
    '화남',
    '짜증',
    '평온',
    '스트레스',
  ];

  // (기본) 카테고리 옵션
  static const List<String> _defaultCategoryOptions = [
    '식비',
    '교통비',
    '문화비',
    '여가비',
    '급여',
    '부수입',
    '기타',
  ];

  @override
  void initState() {
    super.initState();

    // 1번 로직 유지: route argument(DateTime) 받고 VM load
    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      final date = (args is DateTime) ? args : DateTime.now();
      _argDate = date;
      context.read<TodaySpendingViewModel>().load(date);
    });
  }

  // ---------- Utils ----------
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  int _timeInMinutes(int diffAmount) {
    if (diffAmount <= 0) return 0;
    return (diffAmount / 0.11).round();
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return (m == 0) ? '${h}시간' : '${h}시간 ${m}분';
  }

  String _formatKoreanDate(DateTime d) => '${d.year}년 ${d.month}월 ${d.day}일';

  static String _emotionToLottie(String emotion) {
    switch (emotion) {
      case '기쁨':
        return 'assets/animations/Great.json';
      case '슬픔':
        return 'assets/animations/Sad.json';
      case '화남':
        return 'assets/animations/Angry.json';
      case '짜증':
        return 'assets/animations/Annoyed.json';
      case '평온':
        return 'assets/animations/Calm.json';
      case '스트레스':
        return 'assets/animations/Stress.json';
      default:
        return 'assets/animations/Great.json';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // =====================================================
  //  공용: 카테고리 피커 BottomSheet
  // =====================================================
  void _showCategoryPickerModal({
    required BuildContext context,
    required String? current,
    required List<String> items,
    required void Function(String) onSelected,
  }) {
    final list = items.toSet().toList(); // 중복 제거
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
                      children: list.map((category) {
                        return InkWell(
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
                        );
                      }).toList(),
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

  // =====================================================
  //  소비(오늘기록) BottomSheets — TodaySpendingViewModel 연결
  // =====================================================

  void _showAddSpendingBottomSheet({
    required BuildContext context,
    required TodaySpendingViewModel vm,
  }) {
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
          builder: (context, setModalState) {
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
                    child: Column(
                      children: [
                        // 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.chevron_left),
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
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        Center(
                          child: Text(
                            _formatKoreanDate(_argDate ?? DateTime.now()),
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SpendingEntryRow(
                                  categoryLabel: selectedCategory,
                                  onCategoryTap: () {
                                    _showCategoryPickerModal(
                                      context: context,
                                      current: selectedCategory,
                                      items: _defaultCategoryOptions,
                                      onSelected: (val) {
                                        setModalState(() {
                                          selectedCategory = val;
                                          final text =
                                          amountController.text.replaceAll(',', '');
                                          isValidInput = selectedCategory != null &&
                                              text.isNotEmpty &&
                                              int.tryParse(text) != null;
                                        });
                                      },
                                    );
                                  },
                                  amountController: amountController,
                                  noteController: noteController,
                                  onAmountChanged: (value) {
                                    setModalState(() {
                                      final text = value.replaceAll(',', '');
                                      isValidInput = selectedCategory != null &&
                                          text.isNotEmpty &&
                                          int.tryParse(text) != null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: CustomButton(
                            text: '추가',
                            height: 56,
                            enabled: isValidInput,
                            onPressed: () async {
                              if (!isValidInput) return;

                              final amount = double.parse(
                                amountController.text.replaceAll(',', ''),
                              );

                              await vm.addEntry(
                                category: selectedCategory!,
                                amount: amount,
                                note: noteController.text,
                              );

                              if (context.mounted) Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSpendingBottomSheet({
    required BuildContext context,
    required TodaySpendingViewModel vm,
    required SpendingEntry entry,
  }) {
    String? selectedCategory = entry.category;
    final amountController = TextEditingController(
      text: _formatAmount(entry.amount.round()),
    );
    final noteController = TextEditingController(text: entry.note);
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '소비 수정',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                            child: SpendingEntryRow(
                              categoryLabel: selectedCategory,
                              onCategoryTap: () {
                                _showCategoryPickerModal(
                                  context: context,
                                  current: selectedCategory,
                                  items: _defaultCategoryOptions,
                                  onSelected: (val) {
                                    setModalState(() {
                                      selectedCategory = val;
                                      final text =
                                      amountController.text.replaceAll(',', '');
                                      isValidInput = selectedCategory != null &&
                                          text.isNotEmpty &&
                                          int.tryParse(text) != null;
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
                                  isValidInput = selectedCategory != null &&
                                      text.isNotEmpty &&
                                      int.tryParse(text) != null;
                                });
                              },
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: CustomButton(
                            text: '수정',
                            height: 56,
                            enabled: isValidInput,
                            onPressed: () async {
                              if (!isValidInput) return;

                              final amount = double.parse(
                                amountController.text.replaceAll(',', ''),
                              );

                              await vm.updateEntry(
                                entryId: entry.id,
                                category: selectedCategory!,
                                amount: amount,
                                note: noteController.text,
                              );

                              if (context.mounted) Navigator.of(context).pop();
                            },
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

  void _showEditEmotionBottomSheet({
    required BuildContext context,
    required TodaySpendingViewModel vm,
  }) {
    String? selectedEmotion = vm.emotion.isEmpty ? null : vm.emotion;
    final diaryController = TextEditingController(text: vm.comment);

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
                          items: _emotionOptions,
                          onChanged: (val) => setModalState(() => selectedEmotion = val),
                          hintText: '감정 선택',
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: diaryController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: '오늘의 소비일지를 작성해주세요 (100자 이내)',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (text) {
                            if (text.length > 100) {
                              diaryController.text = text.substring(0, 100);
                              diaryController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(offset: diaryController.text.length),
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        CustomDualButton(
                          leftLabel: '취소',
                          rightLabel: '수정',
                          onLeftPressed: () => Navigator.of(context).pop(),
                          onRightPressed: () async {
                            await vm.updateEmotionAndComment(
                              emotion: selectedEmotion ?? '',
                              comment: diaryController.text,
                            );
                            if (context.mounted) Navigator.of(context).pop();
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

  // =====================================================
  //  ✅ 수입 임시 연결 BottomSheet — AddIncomeViewModel
  // =====================================================

  void _showIncomeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final modalHeight = MediaQuery.of(ctx).size.height * 0.85;

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                child: Consumer<AddIncomeViewModel>(
                  builder: (context, incomeVm, _) {
                    final entries = incomeVm.entries;

                    // 임시 카테고리 옵션: 기본 + 커스텀
                    final incomeCategories = [
                      ..._defaultCategoryOptions,
                      ...incomeVm.customCategories,
                    ].toSet().toList();

                    return Column(
                      children: [
                        // 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.chevron_left),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    '수입 입력하기 (임시)',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 48),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            child: Column(
                              children: [
                                ...List.generate(entries.length, (i) {
                                  final e = entries[i];

                                  // ⚠️ 임시: 매 빌드마다 컨트롤러를 생성(큰 문제는 아니지만 최적은 아님)
                                  final amountCtrl = TextEditingController(text: e.amount ?? '');
                                  final noteCtrl = TextEditingController(text: e.content ?? '');

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      children: [
                                        SpendingEntryRow(
                                          categoryLabel: e.category.isEmpty ? null : e.category,
                                          onCategoryTap: () {
                                            _showCategoryPickerModal(
                                              context: context,
                                              current: e.category.isEmpty ? null : e.category,
                                              items: incomeCategories,
                                              onSelected: (val) {
                                                incomeVm.updateEntry(i, category: val);
                                              },
                                            );
                                          },
                                          amountController: amountCtrl,
                                          noteController: noteCtrl,
                                          amountSuffix: '원',
                                          greyBackgroundOnly: true,
                                          onAmountChanged: (value) {
                                            incomeVm.updateEntry(i, amount: value);
                                          },
                                        ),
                                        const SizedBox(height: 8),

                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              final ok = incomeVm.removeEntry(i);
                                              if (!ok) _snack('최소 1줄은 남겨야 해요.');
                                            },
                                            child: const Text(
                                              '이 줄 삭제',
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ),
                                        const Divider(height: 1),
                                      ],
                                    ),
                                  );
                                }),

                                // 행 추가
                                GestureDetector(
                                  onTap: () => incomeVm.addEntry(),
                                  child: Container(
                                    width: double.infinity,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '입금 항목 추가 +',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '총 수입: ${incomeVm.totalFormatted}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 하단 완료 버튼
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: CustomButton(
                            text: '완료',
                            height: 56,
                            enabled: true,
                            onPressed: () => Navigator.of(context).pop(),
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

  // =====================================================
  //  UI Builders
  // =====================================================

  Widget _buildDiaryContent(TodaySpendingViewModel vm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 + 편집
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
              onTap: () => _showEditEmotionBottomSheet(context: context, vm: vm),
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

        Center(
          child: Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Lottie.asset(
                  _emotionToLottie(vm.emotion),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vm.emotion.isEmpty ? '😊 감정 미기록' : '😊 ${vm.emotion}',
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
            vm.comment.isEmpty ? '오늘의 소비일지가 없어요.' : vm.comment,
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

  Widget _buildIncomeBody(BuildContext context) {
    final incomeVm = context.watch<AddIncomeViewModel>();
    final entries = incomeVm.entries;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
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
          child: entries.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '등록된 수입이 없어요',
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
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final amountText = (e.amount ?? '').trim();
              final title = (e.content ?? '').trim().isEmpty
                  ? (e.category.isEmpty ? '수입' : e.category)
                  : e.content!.trim();

              return Column(
                children: [
                  _incomeTile(
                    index: i,
                    entry: e,
                    title: title,
                    amountText: amountText,
                    onEdit: () => _showIncomeBottomSheet(context),
                    onDelete: () => context.read<AddIncomeViewModel>().removeEntry(i),
                  ),
                  if (i < entries.length - 1)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      height: 1,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.black26, width: 1),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingBody(TodaySpendingViewModel vm) {
    // 소비 - 일지
    if (!_isList) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildDiaryContent(vm),
        ),
      );
    }

    // 소비 - 목록
    final entries = vm.entries;
    final totalAmount = vm.totalAmount;
    final dailyLimit = vm.dailyLimit;
    final diffAmount = vm.diffAmount;
    final minutes = _timeInMinutes(diffAmount);
    final isOverLimit = (dailyLimit > 0 && totalAmount > dailyLimit);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
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
                  // 목록
                  entries.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
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
                    children: entries.asMap().entries.map((kv) {
                      final index = kv.key;
                      final e = kv.value;

                      return Column(
                        children: [
                          _buildSpendingEntryWithSwipe(
                            entry: e,
                            onEdit: () => _showEditSpendingBottomSheet(
                              context: context,
                              vm: vm,
                              entry: e,
                            ),
                            onDelete: () => vm.deleteEntry(e.id),
                            isOverLimit: isOverLimit,
                          ),
                          if (index < entries.length - 1)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 1,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),

                  // 합계/차액 (항목 있을 때만)
                  if (entries.isNotEmpty) ...[
                    Container(
                      height: 1,
                      color: const Color(0xFFE0E0E0),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: diffAmount > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFF8FBFF),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
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
                                  color: diffAmount > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('하루소비한도금액', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('${_formatAmount(dailyLimit)}원', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                '${_formatAmount(diffAmount)}원',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: diffAmount > 0 ? Colors.red : const Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),
                          if (diffAmount != 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: diffAmount > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: diffAmount > 0 ? const Color(0xFFEF9A9A) : const Color(0xFF4A90E2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: diffAmount > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      diffAmount > 0
                                          ? '${_formatAmount(diffAmount)}원치, 목표도달까지 ${_formatTime(minutes)}이 미뤄졌어요! 내일 더 힘내봐요!'
                                          : '${_formatAmount(diffAmount.abs())}원치, 목표도달까지 ${_formatTime(_timeInMinutes(diffAmount.abs()))}이 당겨졌어요! 오늘도 잘했어요!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: diffAmount > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2),
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

  Widget _buildSpendingEntryWithSwipe({
    required SpendingEntry entry,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool isOverLimit,
  }) {
    return Dismissible(
      key: Key('entry_${entry.id}'),
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
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 태그
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                entry.category,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 노트 + 편집
                Row(
                  children: [
                    Text(
                      entry.note.isEmpty ? entry.category : entry.note,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.edit, color: Color(0xFF999999), size: 11),
                        ),
                      ),
                    ),
                  ],
                ),

                Text(
                  '${_formatAmount(entry.amount.round())}원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverLimit ? const Color(0xFFE53E3E) : const Color(0xFF3182CE),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodaySpendingViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (vm.error != null) {
      return Scaffold(
        body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))),
      );
    }

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
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 수입/소비 토글
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TwoOptionToggle(
                    labels: const ['수입', '소비'],
                    selected: _isIncome ? '수입' : '소비',
                    onChanged: (v) => setState(() {
                      _isIncome = (v == '수입');
                      if (_isIncome) _isList = true; // 수입은 목록만
                    }),
                    width: 120,
                    height: 34,
                  ),
                ],
              ),
            ),

            // 소비일 때만 목록/일지 토글
            if (!_isIncome) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TwoOptionToggle(
                      labels: const ['목록', '일지'],
                      selected: _isList ? '목록' : '일지',
                      onChanged: (v) => setState(() => _isList = (v == '목록')),
                      width: 120,
                      height: 34,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 콘텐츠
            Expanded(
              child: _isIncome ? _buildIncomeBody(context) : _buildSpendingBody(vm),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: () {
                  if (_isIncome) {
                    _showIncomeBottomSheet(context);
                  } else {
                    _showAddSpendingBottomSheet(context: context, vm: vm);
                  }
                },
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
                      _isIncome ? '수입 입력하기' : '소비 입력하기',
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
    );
  }
}

/// ✅ 수입 리스트 타일(임시)
Widget _incomeTile({
  required int index,
  required IncomeEntry entry,
  required String title,
  required String amountText,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 태그
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            entry.category.isEmpty ? '카테고리 미선택' : entry.category,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.edit, color: Color(0xFF999999), size: 11),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              amountText.isEmpty ? '-' : '$amountText원',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onDelete,
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );
}
