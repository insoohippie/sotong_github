import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../component/buttons/custom_button.dart';
import '../../../../component/theme/app_colors.dart';
import '../../../../model/record/record_entry.dart';
import '../../../../view_model/communication/communication_view_model.dart';

void showDateDetailModal({
  required BuildContext context,
  required CommunicationViewModel vm,
  required int day,
}) {
  final hasEmotion = vm.hasEmotionRecord(day);
  final hasAmount = vm.spendingAmountForDay(day) > 0;
  final hasRecord = hasEmotion || hasAmount;

  // 소비 미기록 날: 플랜 챗 온보딩 모달 느낌 — 높이·패딩·라운드·그림자 통일
  const double emptyDateModalHeight = 140;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);

      final theme = Theme.of(context);
      final content = Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: hasRecord
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            boxShadow: hasRecord
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, -4),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: hasRecord
                  ? const EdgeInsets.fromLTRB(24, 12, 24, 32)
                  : const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasRecord) const _HandleBar(),
                  hasRecord
                      ? _RecordedDateContent(vm: vm, day: day)
                      : _EmptyDateContent(vm: vm, day: day),
                ],
              ),
            ),
          ),
        ),
      );

      return hasRecord
          ? FractionallySizedBox(heightFactor: 0.9, child: content)
          : SizedBox(height: emptyDateModalHeight, child: content);
    },
  );
}

class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _RecordedDateContent extends StatelessWidget {
  const _RecordedDateContent({required this.vm, required this.day});

  final CommunicationViewModel vm;
  final int day;

  @override
  Widget build(BuildContext context) {
    final emotionLabel = vm.emotionLabelForDay(day);
    final amount = vm.spendingAmountForDay(day);
    final diary = vm.diaryForDay(day);
    final entries = vm.entriesForDay(day); // List<SpendingEntry> 기대

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(vm: vm, day: day),
        const SizedBox(height: 20),
        if (emotionLabel.trim().isNotEmpty) ...[
          _EmotionRow(emotionLabel: emotionLabel),
          const SizedBox(height: 20),
        ],
        _SpendingList(entries: entries, total: amount),
        if (diary.isNotEmpty) ...[
          const SizedBox(height: 20),
          _DiaryBox(diary: diary),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vm, required this.day});

  final CommunicationViewModel vm;
  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${vm.selectedMonth}월 $day일',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: 수정 페이지로 이동
          },
          icon: const Icon(Icons.edit, size: 22, color: AppColors.primary),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _EmotionRow extends StatelessWidget {
  const _EmotionRow({required this.emotionLabel});

  final String emotionLabel;

  static String _lottiePathForEmotion(String emotion) {
    switch (emotion) {
      case '평온':
        return 'assets/animations/emotion_calm.json';
      case '좋음':
        return 'assets/animations/emotion_good.json';
      case '슬픔':
        return 'assets/animations/emotion_sad.json';
      case '스트레스':
        return 'assets/animations/emotion_stress.json';
      case '동기부여':
        return 'assets/animations/emotion_motivation.json';
      case '아무 감정 없음':
        return 'assets/animations/emotion_none.json';
      default:
        return 'assets/animations/emotion_calm.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : AppColors.lightBlue;
    final path = _lottiePathForEmotion(
      emotionLabel.trim().isEmpty ? '평온' : emotionLabel,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Lottie.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('🙂', style: TextStyle(fontSize: 24)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            emotionLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingList extends StatelessWidget {
  const _SpendingList({required this.entries, required this.total});

  final List<RecordEntry> entries;
  final int total;

  String _format(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소비 목록',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '소비 내역이 없어요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...entries.map(
                  (e) => _SpendingItem(
                category: e.category,
                amount: e.amount.round(),
                note: e.note,
              ),
            ),
          if (entries.isNotEmpty) ...[
            const Divider(height: 24),
            Builder(
              builder: (context) {
                final t = Theme.of(context);
                final isDark = t.brightness == Brightness.dark;
                final totalBg = isDark
                    ? t.colorScheme.primaryContainer.withOpacity(0.3)
                    : AppColors.lightBlue;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: totalBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '총 합산',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: t.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${_format(total)}원',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: t.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SpendingItem extends StatelessWidget {
  const _SpendingItem({
    required this.category,
    required this.amount,
    required this.note,
  });

  final String category;
  final int amount;
  final String? note;

  String _format(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (note != null && note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      note!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${_format(amount)}원',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBox extends StatelessWidget {
  const _DiaryBox({required this.diary});
  final String diary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '소비 일지',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            diary,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDateContent extends StatelessWidget {
  const _EmptyDateContent({required this.vm, required this.day});

  final CommunicationViewModel vm;
  final int day;

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: '소비 등록하기',
      onPressed: () {
        Navigator.pop(context);
        // TODO: 소비 입력 페이지로 이동
      },
      height: 60,
    );
  }
}
