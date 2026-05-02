import 'package:flutter/material.dart';

import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/record/today_spending_view_model.dart';

class TodayRecordSpendingSection extends StatelessWidget {
  final TodaySpendingViewModel vm;
  final void Function(RecordEntry entry) onEdit;
  final void Function(RecordEntry entry) onDelete;
  final VoidCallback onAdd;

  const TodayRecordSpendingSection({
    super.key,
    required this.vm,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

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

  @override
  Widget build(BuildContext context) {
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
                  entries.isEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: Colors.grey[400]),
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
                            onEdit: () => onEdit(e),
                            onDelete: () => onDelete(e),
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

                  // ✅ 리스트 아래 / 총액 위 + 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: onAdd,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(17),
                            border: Border.all(
                              color: const Color(0xFF4A90E2).withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF4A90E2),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (entries.isNotEmpty) ...[
                    Container(
                      height: 1,
                      color: const Color(0xFFE0E0E0),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: diffAmount > 0
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFF8FBFF),
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
                                  color: diffAmount > 0
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '하루소비한도금액',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                '${_formatAmount(dailyLimit)}원',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
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
                                  color: diffAmount > 0
                                      ? Colors.red
                                      : const Color(0xFF4A90E2),
                                ),
                              ),
                            ],
                          ),
                          if (diffAmount != 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: diffAmount > 0
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: diffAmount > 0
                                      ? const Color(0xFFEF9A9A)
                                      : const Color(0xFF4A90E2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: diffAmount > 0
                                        ? const Color(0xFFE53935)
                                        : const Color(0xFF4A90E2),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      diffAmount > 0
                                          ? '${_formatAmount(diffAmount)}원치, 목표도달까지 ${_formatTime(minutes)}이 미뤄졌어요! 내일 더 힘내봐요!'
                                          : '${_formatAmount(diffAmount.abs())}원치, 목표도달까지 ${_formatTime(_timeInMinutes(diffAmount.abs()))}이 당겨졌어요! 오늘도 잘했어요!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: diffAmount > 0
                                            ? const Color(0xFFE53935)
                                            : const Color(0xFF4A90E2),
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
    required RecordEntry entry,
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
                          child: Icon(Icons.edit,
                              color: Color(0xFF999999), size: 11),
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
                    color: isOverLimit
                        ? const Color(0xFFE53E3E)
                        : const Color(0xFF3182CE),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}