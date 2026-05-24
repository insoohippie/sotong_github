import 'package:flutter/material.dart';

import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/record/today_income_view_model.dart';

class TodayRecordIncomeSection extends StatelessWidget {
  final TodayIncomeViewModel vm;
  final bool hasUnsavedChanges;
  final bool hasEntryChanges;
  final Future<void> Function() onSave;
  final void Function(RecordEntry entry) onEdit;
  final void Function(RecordEntry entry) onDelete;
  final VoidCallback onAdd;

  const TodayRecordIncomeSection({
    super.key,
    required this.vm,
    required this.hasUnsavedChanges,
    required this.hasEntryChanges,
    required this.onSave,
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수입 항목 삭제'),
        content: const Text('이 수입 항목을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final entries = vm.entries;
    final totalIncome = vm.totalAmount;

    final saveButtonHeight = hasUnsavedChanges ? 96.0 : 72.0;
    final idleSummaryGap = hasEntryChanges ? 0.0 : 96.0;
    final saveButtonReservedHeight =
        MediaQuery.paddingOf(context).bottom +
        saveButtonHeight +
        idleSummaryGap;

    return Stack(
      children: [
        Positioned.fill(
          bottom: saveButtonReservedHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildIncomeCard(
              context: context,
              entries: entries,
              totalIncome: totalIncome,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _buildSaveButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeCard({
    required BuildContext context,
    required List<RecordEntry> entries,
    required int totalIncome,
  }) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              child: _buildEntryList(context: context, entries: entries),
            ),
            _buildAddButton(),
            if (entries.isNotEmpty)
              _buildSummaryPanel(totalIncome: totalIncome),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList({
    required BuildContext context,
    required List<RecordEntry> entries,
  }) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      );
    }

    return Scrollbar(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => _buildEntrySeparator(),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildIncomeEntryWithSwipe(
            context: context,
            entry: entry,
            onEdit: () => onEdit(entry),
            onDelete: () => onDelete(entry),
          );
        },
      ),
    );
  }

  Widget _buildEntrySeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 2,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF4A90E2).withOpacity(0.25),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 44,
            height: 36,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: const Color(0xFFF4F7FB),
                foregroundColor: const Color(0xFF4A90E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: const Color(0xFF4A90E2).withOpacity(0.3),
                  ),
                ),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPanel({required int totalIncome}) {
    return Column(
      children: [
        Container(
          height: 1,
          color: const Color(0xFFE0E0E0),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FBFF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 수입',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${_formatAmount(totalIncome)}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final backgroundColor = hasUnsavedChanges
        ? const Color(0xFF4A90E2)
        : const Color(0xFFE5E7EB);
    final textColor = hasUnsavedChanges ? Colors.white : Colors.grey[500]!;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: hasUnsavedChanges ? () => onSave() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          '저장하기',
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeEntryWithSwipe({
    required BuildContext context,
    required RecordEntry entry,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Dismissible(
      key: ValueKey('income_${entry.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
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
      child: _IncomeTile(entry: entry, onEdit: onEdit),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final RecordEntry entry;
  final VoidCallback onEdit;

  const _IncomeTile({required this.entry, required this.onEdit});

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = entry.note.isNotEmpty ? entry.note : entry.category;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.edit, color: Color(0xFF999999), size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.isEmpty ? '수입' : title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatAmount(entry.amount.round())}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
