import 'package:flutter/material.dart';
import '../../../../model/record/spending_entry.dart';
import '../../../../view_model/communication/communication_view_model.dart';

void showDateDetailModal({
  required BuildContext context,
  required CommunicationViewModel vm,
  required int day,
}) {
  final hasEmotion = vm.hasEmotionRecord(day);
  final hasAmount = vm.spendingAmountForDay(day) > 0;
  final hasRecord = hasEmotion || hasAmount;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);

      return FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HandleBar(),
                    hasRecord
                        ? _RecordedDateContent(vm: vm, day: day)
                        : _EmptyDateContent(vm: vm, day: day),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
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
    final emoji = vm.emotionEmojiForDay(day);
    final amount = vm.spendingAmountForDay(day);
    final diary = vm.diaryForDay(day);
    final entries = vm.entriesForDay(day); // List<SpendingEntry> 기대

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(vm: vm, day: day),
        if (emoji.isNotEmpty) ...[
          _EmotionRow(vm: vm, emoji: emoji),
          const SizedBox(height: 12),
        ],
        _SpendingList(entries: entries, total: amount),
        const SizedBox(height: 12),
        _DiaryBox(diary: diary),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${vm.selectedMonth}월 $day일',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: 수정 페이지로 이동
          },
          icon: const Icon(Icons.edit, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _EmotionRow extends StatelessWidget {
  const _EmotionRow({required this.vm, required this.emoji});

  final CommunicationViewModel vm;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(vm.emotionNameFromEmoji(emoji), style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}

class _SpendingList extends StatelessWidget {
  const _SpendingList({required this.entries, required this.total});

  final List<SpendingEntry> entries;
  final int total;

  String _format(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('소비 목록', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('소비 내역이 없어요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            )
          else
            ...entries.map((e) => _SpendingItem(
              category: e.category,
              amount: e.amount.round(),
              note: e.note,
            )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('총 합산', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(
                '${_format(total)}원',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (note != null && note!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(note!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
              ],
            ),
          ),
          Text('${_format(amount)}원',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('소비 일지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(diary, style: const TextStyle(fontSize: 13)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${vm.selectedMonth}월 $day일',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('소비를 기록해주세요', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('소비입력하러 가기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
