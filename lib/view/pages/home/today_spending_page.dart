// lib/view/pages/record/today_spending_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../../component/inputs/custom_number_field.dart';
import '../../../component/inputs/custom_text_field.dart';
import '../../../component/buttons/select_button.dart';

import '../../../model/record/spending_entry.dart';
import '../../../view_model/home/today_spending_view_model.dart';

class TodaySpendingPage extends StatefulWidget {
  const TodaySpendingPage({super.key});

  @override
  State<TodaySpendingPage> createState() => _TodaySpendingPageState();
}

class _TodaySpendingPageState extends State<TodaySpendingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  DateTime? _argDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));

    Future.microtask(() {
      final args = ModalRoute.of(context)?.settings.arguments;
      final date = (args is DateTime) ? args : DateTime.now();
      _argDate = date;
      context.read<TodaySpendingViewModel>().load(date);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
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

  // ---------- Dialogs ----------
  void _showAddDialog(BuildContext context, TodaySpendingViewModel vm) {
    String? selectedCategory;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    bool isValid = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('소비 등록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectButton(
                      value: selectedCategory,
                      items: ['식비', '교통비', '문화비', '여가비', '기타'],
                      onChanged: (v) {
                        setState(() {
                          selectedCategory = v;
                          final text = amountController.text.replaceAll(',', '');
                          isValid = selectedCategory != null &&
                              text.isNotEmpty &&
                              int.tryParse(text) != null;
                        });
                      },
                      hintText: '카테고리 선택',
                    ),
                    const SizedBox(height: 16),
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
                          isValid = selectedCategory != null &&
                              text.isNotEmpty &&
                              int.tryParse(text) != null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isValid
                      ? () async {
                    final amount = double.parse(amountController.text.replaceAll(',', ''));
                    await vm.addEntry(
                      category: selectedCategory!,
                      amount: amount,
                      note: noteController.text,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                      : null,
                  child: const Text('등록', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, TodaySpendingViewModel vm, SpendingEntry entry) {
    String? selectedCategory = entry.category;
    final amountController = TextEditingController(text: entry.amount.toStringAsFixed(0));
    final noteController = TextEditingController(text: entry.note);
    bool isValid = true;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('소비 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectButton(
                    value: selectedCategory,
                    items: ['식비', '교통비', '문화비', '여가비', '기타'],
                    onChanged: (v) => setState(() => selectedCategory = v),
                    hintText: '카테고리 선택',
                  ),
                  const SizedBox(height: 16),
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
                        isValid = selectedCategory != null &&
                            text.isNotEmpty &&
                            int.tryParse(text) != null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: isValid
                    ? () async {
                  final amount = double.parse(amountController.text.replaceAll(',', ''));
                  await vm.updateEntry(
                    entryId: entry.id,
                    category: selectedCategory!,
                    amount: amount,
                    note: noteController.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
                    : null,
                child: const Text('수정', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditEmotionDialog(BuildContext context, TodaySpendingViewModel vm) {
    String? selectedEmotion = vm.emotion.isEmpty ? null : vm.emotion;
    final diaryController = TextEditingController(text: vm.comment);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('감정 및 소비일지 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectButton(
                    value: selectedEmotion,
                    items: ['기쁨', '슬픔', '화남', '짜증', '평온', '스트레스'],
                    onChanged: (v) => setState(() => selectedEmotion = v),
                    hintText: '감정 선택',
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: diaryController,
                    hintText: '오늘의 소비일지를 작성해주세요',
                    onChanged: (text) {
                      if (text.length > 100) {
                        diaryController.text = text.substring(0, 100);
                        diaryController.selection = TextSelection.fromPosition(
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
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () async {
                  await vm.updateEmotionAndComment(
                    emotion: selectedEmotion ?? '',
                    comment: diaryController.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('수정', style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TodaySpendingViewModel>();

    if (vm.isLoading) {
      return const Scaffold(body: SafeArea(child: Center(child: CircularProgressIndicator())));
    }
    if (vm.error != null) {
      return Scaffold(body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))));
    }

    final total = vm.totalAmount;
    final limit = vm.dailyLimit;
    final diff = vm.diffAmount;
    final minutes = _timeInMinutes(diff);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
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
                      child: Text('오늘의 소비', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 탭바 (기존 유지)
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
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _tabController.index == 0 ? 2 : MediaQuery.of(context).size.width * 0.5 - 2,
                      top: 2,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5 - 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(0),
                            child: SizedBox(
                              height: 44,
                              child: Center(
                                child: Text(
                                  '소비 리스트',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: _tabController.index == 0 ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(1),
                            child: SizedBox(
                              height: 44,
                              child: Center(
                                child: Text(
                                  '소비일지',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: _tabController.index == 1 ? FontWeight.bold : FontWeight.w500,
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

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ===== 소비 리스트 탭 =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // 리스트 + 합계 카드
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: vm.entries.isEmpty
                                      ? Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 16),
                                        Text('등록된 소비가 없어요', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  )
                                      : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: vm.entries.length,
                                    separatorBuilder: (_, __) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 20),
                                      height: 1,
                                      decoration: BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.red.withOpacity(0.3), width: 1)),
                                      ),
                                    ),
                                    itemBuilder: (_, i) {
                                      final e = vm.entries[i];
                                      return Dismissible(
                                        key: Key('entry_${e.id}'),
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
                                        onDismissed: (_) => vm.deleteEntry(e.id),
                                        child: _entryTile(
                                          entry: e,
                                          isOverLimit: (limit > 0 && total > limit),
                                          onEdit: () => _showEditDialog(context, vm, e),
                                          formatAmount: _formatAmount,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                if (vm.entries.isNotEmpty) ...[
                                  Container(height: 1, color: const Color(0xFFE0E0E0), margin: const EdgeInsets.symmetric(horizontal: 16)),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: diff > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFF8FBFF),
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
                                            const Text('오늘의 소비', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                                            Text(
                                              '${_formatAmount(total)}원',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: diff > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('하루소비한도금액', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                            Text('${_formatAmount(limit)}원', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('차액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
                                            Text(
                                              '${_formatAmount(diff)}원',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: diff > 0 ? Colors.red : const Color(0xFF4A90E2),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (diff != 0) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: diff > 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: diff > 0 ? const Color(0xFFEF9A9A) : const Color(0xFF4A90E2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.access_time, size: 16, color: diff > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2)),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    diff > 0
                                                        ? '${_formatAmount(diff)}원치, 목표도달까지 ${_formatTime(minutes)}이 미뤄졌어요! 내일 더 힘내봐요!'
                                                        : '${_formatAmount(diff.abs())}원치, 목표도달까지 ${_formatTime(_timeInMinutes(diff.abs()))}이 당겨졌어요! 오늘도 잘했어요!',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: diff > 0 ? const Color(0xFFE53935) : const Color(0xFF4A90E2),
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        GestureDetector(
                          onTap: () => _showAddDialog(context, vm),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: const Center(
                              child: Text(
                                '소비내역 추가 +',
                                style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===== 소비일지 탭 =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('오늘의 감정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => _showEditEmotionDialog(context, vm),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                                    child: const Center(child: Icon(Icons.edit, color: Color(0xFF9E9E9E), size: 10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Center(
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 120,
                                    height: 120,
                                    child: Lottie.asset(
                                      _emotionToLottie(vm.emotion),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    vm.emotion.isEmpty ? '😊 감정 미기록' : '😊 ${vm.emotion}',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            Text('소비일지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
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
                                vm.comment.isEmpty ? '오늘의 소비일지가 없어요.' : vm.comment,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                              ),
                            ),
                          ],
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
    );
  }

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
        return 'assets/animations/Great.json'; // 기본
    }
  }
}

Widget _entryTile({
  required SpendingEntry entry,
  required bool isOverLimit,
  required VoidCallback onEdit,
  required String Function(int) formatAmount,
}) {
  final amountInt = entry.amount.round();

  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
          child: Text(
            entry.category,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  entry.note.isEmpty ? entry.category : entry.note,
                  style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.edit, color: Color(0xFF999999), size: 11)),
                  ),
                ),
              ],
            ),
            Text(
              '${formatAmount(amountInt)}원',
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
  );
}
