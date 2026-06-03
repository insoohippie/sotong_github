import 'package:flutter/material.dart';

import '../../../../../component/buttons/small_rounded_button.dart';
import '../../../../../component/theme/app_colors.dart';
import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/record/today_spending_view_model.dart';

class TodayRecordSpendingSection extends StatelessWidget {
  static const Color _accentColor = Color(0xFF4A90E2);
  static const Color _amountBlue = Color(0xFF3182CE);
  static const Color _dangerColor = Color(0xFFE53935);
  static const Color _dangerAmountColor = Color(0xFFE53E3E);
  static const Color _summaryLightBlue = Color(0xFFF8FBFF);
  static const Color _summaryLightRed = Color(0xFFFFEBEE);
  static const Color _calloutLightBlue = Color(0xFFE3F2FD);
  static const Color _chipLightBackground = Color(0xFFF0F0F0);

  final TodaySpendingViewModel vm;
  final bool hasUnsavedChanges;
  final bool hasEntryChanges;
  final Future<void> Function() onSave;
  final void Function(RecordEntry entry) onEdit;
  final void Function(RecordEntry entry) onDelete;
  final VoidCallback onAdd;

  const TodayRecordSpendingSection({
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

  String _formatTime(int minutes) {
    if (minutes < 60) return '$minutes분';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return (m == 0) ? '$h시간' : '$h시간 $m분';
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

  @override
  Widget build(BuildContext context) {
    final entries = vm.entries;
    final totalAmount = vm.totalAmount;
    final dailyLimit = vm.dailyLimit;
    final diffAmount = vm.diffAmount;
    final minutes = vm.diffTimeMinutes;
    final isOverLimit = (dailyLimit > 0 && totalAmount > dailyLimit);
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
            child: _buildSpendingCard(
              context: context,
              entries: entries,
              totalAmount: totalAmount,
              dailyLimit: dailyLimit,
              diffAmount: diffAmount,
              minutes: minutes,
              isOverLimit: isOverLimit,
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
            child: _buildSaveButton(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingCard({
    required BuildContext context,
    required List<RecordEntry> entries,
    required int totalAmount,
    required int dailyLimit,
    required int diffAmount,
    required int minutes,
    required bool isOverLimit,
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
              child: _buildEntryList(
                context: context,
                entries: entries,
                isOverLimit: isOverLimit,
              ),
            ),
            _buildAddButton(context),
            if (entries.isNotEmpty)
              _buildSummaryPanel(
                context: context,
                totalAmount: totalAmount,
                dailyLimit: dailyLimit,
                diffAmount: diffAmount,
                minutes: minutes,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList({
    required BuildContext context,
    required List<RecordEntry> entries,
    required bool isOverLimit,
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
                '등록된 소비가 없어요',
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
        separatorBuilder: (_, __) => _buildEntrySeparator(isOverLimit),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return _buildSpendingEntryWithSwipe(
            context: context,
            entry: entry,
            onEdit: () => onEdit(entry),
            onDelete: () => onDelete(entry),
            isOverLimit: isOverLimit,
          );
        },
      ),
    );
  }

  Widget _buildEntrySeparator(bool isOverLimit) {
    final color = isOverLimit
        ? Colors.red.withValues(alpha: 0.3)
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
    required int totalAmount,
    required int dailyLimit,
    required int diffAmount,
    required int minutes,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    final isOverBudget = diffAmount > 0;
    final summaryBackground = isOverBudget
        ? (isDark
              ? _tintedSurface(context, _dangerColor, 0.12)
              : _summaryLightRed)
        : (isDark
              ? _tintedSurface(context, _accentColor, 0.10)
              : _summaryLightBlue);
    final calloutBackground = isOverBudget
        ? (isDark
              ? _tintedSurface(context, _dangerColor, 0.18)
              : _summaryLightRed)
        : (isDark
              ? _tintedSurface(context, _accentColor, 0.16)
              : _calloutLightBlue);
    final calloutBorderColor = isOverBudget
        ? (isDark
              ? _dangerColor.withValues(alpha: 0.50)
              : const Color(0xFFEF9A9A))
        : (isDark
              ? _accentColor.withValues(alpha: 0.50)
              : _accentColor);
    final labelColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;

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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '오늘의 소비',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    '${_formatAmount(totalAmount)}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? _dangerColor : _accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '하루소비한도금액',
                    style: TextStyle(fontSize: 14, color: secondaryColor),
                  ),
                  Text(
                    '${_formatAmount(dailyLimit)}원',
                    style: TextStyle(fontSize: 14, color: secondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '차액',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    '${_formatAmount(diffAmount)}원',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? Colors.red : _accentColor,
                    ),
                  ),
                ],
              ),
              if (diffAmount != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: calloutBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: calloutBorderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isOverBudget ? _dangerColor : _accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          diffAmount > 0
                              ? '${_formatAmount(diffAmount)}원치, 목표도달까지 ${_formatTime(minutes)}이 미뤄졌어요! 내일 더 힘내봐요!'
                              : '${_formatAmount(diffAmount.abs())}원치, 목표도달까지 ${_formatTime(minutes)}이 당겨졌어요! 오늘도 잘했어요!',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverBudget ? _dangerColor : _accentColor,
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

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasUnsavedChanges
                ? () {
                    onSave();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              disabledBackgroundColor: backgroundColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              hasUnsavedChanges ? '저장하기' : '저장하기',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingEntryWithSwipe({
    required BuildContext context,
    required RecordEntry entry,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool isOverLimit,
  }) {
    final theme = Theme.of(context);
    final isDark = _isDark(context);
    final chipBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : _chipLightBackground;
    final chipTextColor = theme.colorScheme.onSurfaceVariant;
    final editIconColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF999999);

    return Dismissible(
      key: ValueKey('spending_${entry.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteEntry(context),
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
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.all(20),
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
                    entry.category,
                    style: TextStyle(
                      color: chipTextColor,
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
                    decoration: BoxDecoration(
                      color: chipBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.edit,
                        color: editIconColor,
                        size: 12,
                      ),
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
                  entry.note.isEmpty ? entry.category : entry.note,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatAmount(entry.amount.round())}원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverLimit ? _dangerAmountColor : _amountBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteEntry(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '소비 항목 삭제',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('이 소비 항목을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                '예',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
