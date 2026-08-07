import 'package:flutter/material.dart';

import '../../../../../component/buttons/small_rounded_button.dart';
import '../../../../../component/theme/app_colors.dart';
import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/record/today_income_view_model.dart';

class TodayRecordIncomeSection extends StatelessWidget {
  static const Color _accentColor = Color(0xFF4A90E2);
  static const Color _summaryLightBackground = Color(0xFFF8FBFF);
  static const Color _chipLightBackground = Color(0xFFF0F0F0);

  final TodayIncomeViewModel vm;
  final bool hasUnsavedChanges;
  final bool hasEntryChanges;
  final Future<void> Function() onSave;
  final void Function(RecordEntry entry) onEdit;
  final void Function(RecordEntry entry) onDelete;
  final VoidCallback onAdd;
  final bool readOnly;

  const TodayRecordIncomeSection({
    super.key,
    required this.vm,
    required this.hasUnsavedChanges,
    required this.hasEntryChanges,
    required this.onSave,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    this.readOnly = false,
  });

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _tintedSurface(BuildContext context, Color tint, double alpha) {
    final theme = Theme.of(context);
    if (!_isDark(context)) return tint;
    return Color.alphaBlend(
      tint.withValues(alpha: alpha),
      theme.colorScheme.surface,
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

    final saveButtonHeight = readOnly
        ? 0.0
        : hasUnsavedChanges
        ? 96.0
        : 72.0;
    final idleSummaryGap = readOnly
        ? 0.0
        : hasEntryChanges
        ? 0.0
        : 96.0;
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
            child: readOnly ? const SizedBox.shrink() : _buildSaveButton(context),
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
    final theme = Theme.of(context);
    final isDark = _isDark(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: theme.dividerColor) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
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
            _buildAddButton(context),
            if (entries.isNotEmpty)
              _buildSummaryPanel(context: context, totalIncome: totalIncome),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList({
    required BuildContext context,
    required List<RecordEntry> entries,
  }) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.55,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 수입이 없어요',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
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
        separatorBuilder: (_, __) => _buildEntrySeparator(context),
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

  Widget _buildEntrySeparator(BuildContext context) {
    final color = _isDark(context)
        ? Theme.of(context).dividerColor
        : _accentColor.withValues(alpha: 0.25);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 2,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: color,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    if (readOnly) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = _isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: SmallRoundedButton(
          text: '추가',
          backgroundColor: isDark
              ? theme.colorScheme.surface
              : AppColors.greyBackground,
          textColor: theme.colorScheme.onSurface,
          borderColor: isDark ? theme.dividerColor : Colors.grey.shade300,
          onPressed: onAdd,
        ),
      ),
    );
  }

  Widget _buildSummaryPanel({
    required BuildContext context,
    required int totalIncome,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    final summaryBackground = isDark
        ? _tintedSurface(context, _accentColor, 0.10)
        : _summaryLightBackground;

    return Column(
      children: [
        Container(
          height: 1,
          color: isDark ? theme.dividerColor : const Color(0xFFE0E0E0),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        Container(
          decoration: BoxDecoration(
            color: summaryBackground,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '오늘의 수입',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${_formatAmount(totalIncome)}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = hasUnsavedChanges
        ? const Color(0xFF4A90E2)
        : isDark
        ? theme.colorScheme.surface
        : const Color(0xFFE5E7EB);
    final textColor = hasUnsavedChanges
        ? Colors.white
        : isDark
        ? theme.colorScheme.onSurfaceVariant
        : Colors.grey[500]!;

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
    final tile = _IncomeTile(
      entry: entry,
      onEdit: onEdit,
      readOnly: readOnly,
    );
    if (readOnly) return tile;

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
      child: tile,
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final RecordEntry entry;
  final VoidCallback onEdit;
  final bool readOnly;

  const _IncomeTile({
    required this.entry,
    required this.onEdit,
    this.readOnly = false,
  });

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = entry.note.isNotEmpty ? entry.note : entry.category;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : TodayRecordIncomeSection._chipLightBackground;
    final chipTextColor = theme.colorScheme.onSurfaceVariant;
    final editIconColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF999999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
                  color: chipBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.category.isEmpty ? '카테고리 미선택' : entry.category,
                  style: TextStyle(
                    color: chipTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              if (!readOnly)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: chipBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.edit, color: editIconColor, size: 12),
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
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_formatAmount(entry.amount.round())}원',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TodayRecordIncomeSection._accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
