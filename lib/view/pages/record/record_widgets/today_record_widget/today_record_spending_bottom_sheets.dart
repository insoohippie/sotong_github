import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/buttons/period_toggle.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

import '../../../../../model/category/ref_category_item.dart';
import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/category/spending_category_view_model.dart';
import '../drag_grid.dart';
import '../spending_widget/record_spending_category_sheet.dart';
import '../spending_widget/spending_input_entry.dart';

const _spendingSheetDismissDelay = Duration(milliseconds: 320);

Future<void> _waitForSpendingSheetDismissed() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(_spendingSheetDismissDelay);
}

Future<RecordEntry?> showTodayRecordAddSpendingBottomSheet({
  required BuildContext context,
}) async {
  final tempEntry = _createSpendingTempEntry();

  final result = await _showSpendingEntryBottomSheet(
    context: context,
    title: '소비 추가하기',
    originEntryId: 'temp_spending',
    entry: tempEntry,
    buttonText: '추가',
  );

  _disposeTempEntry(tempEntry);
  return result;
}

Future<RecordEntry?> showTodayRecordEditSpendingBottomSheet({
  required BuildContext context,
  required RecordEntry entry,
}) async {
  final tempEntry = _createSpendingTempEntry(
    category: entry.category,
    categoryKey: entry.categoryKey,
    amount: entry.amount,
    note: entry.note,
  );

  final result = await _showSpendingEntryBottomSheet(
    context: context,
    title: '소비 수정',
    originEntryId: entry.id,
    entry: tempEntry,
    buttonText: '수정',
  );

  _disposeTempEntry(tempEntry);
  return result;
}

Future<RecordEntry?> _showSpendingEntryBottomSheet({
  required BuildContext context,
  required String title,
  required String originEntryId,
  required Map<String, dynamic> entry,
  required String buttonText,
}) async {
  bool isClosing = false;
  final categoryVM = context.read<SpendingCategoryViewModel>();

  bool canSubmit() {
    final categoryKey = ((entry['categoryKey'] as String?) ?? '').trim();
    final amount = ((entry['amount'] as num?)?.toDouble() ?? 0.0);
    return categoryKey.isNotEmpty && amount > 0;
  }

  bool showCategoryPicker = false;

  var committedRef = <RefCategoryItem>[];
  var localRef = <RefCategoryItem>[];
  final pendingRemoveKeys = <String>{};

  bool isPlanTab = true;
  bool editMode = false;
  bool showAdd = false;
  bool showEmojiPicker = false;
  String selectedEmoji = '💰';
  final tempNameCtrl = TextEditingController();

  void closeAddUI() {
    showAdd = false;
    showEmojiPicker = false;
    tempNameCtrl.clear();
    selectedEmoji = '💰';
  }

  void enterEditMode() {
    if (isPlanTab) return;
    editMode = true;
    closeAddUI();
  }

  void cancelEditChanges() {
    localRef = List<RefCategoryItem>.from(committedRef);
    pendingRemoveKeys.clear();
    editMode = false;
    closeAddUI();
  }

  bool hasUnsavedEditChanges() {
    if (!editMode) return false;
    if (pendingRemoveKeys.isNotEmpty) return true;

    final a = committedRef.map((e) => e.categoryKey).toList();
    final b = localRef.map((e) => e.categoryKey).toList();

    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return true;
    }
    return false;
  }

  Future<bool> confirmDiscardDialog(BuildContext dialogContext) async {
    final res = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: true,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text(
            '변경사항이 있어요',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('저장하지 않고 닫으면 변경사항이 사라져요.\n그래도 닫을까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('계속 편집'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text(
                '폐기하고 닫기',
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
    return res ?? false;
  }

  void showSheetToast(BuildContext ctx, String message) {
    final overlay = Overlay.of(ctx, rootOverlay: true);

    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 140,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 1200), () {
      overlayEntry.remove();
    });
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget buildCategoryChip({
    required String name,
    required String emoji,
    required bool selected,
    required double width,
    required VoidCallback onTap,
    VoidCallback? onDeleteRef,
  }) {
    final showDelete = (!isPlanTab && editMode && onDeleteRef != null);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedBackground = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF3F4F6);
    final unselectedBorder = isDark
        ? theme.dividerColor
        : const Color(0xFFE5E7EB);
    final unselectedText = isDark
        ? theme.colorScheme.onSurface
        : const Color(0xFF111827);
    final deleteBackground = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final deleteIconColor = isDark
        ? theme.colorScheme.onSurfaceVariant
        : const Color(0xFF9CA3AF);

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: !isPlanTab
            ? () {
                enterEditMode();
              }
            : null,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : unselectedBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : unselectedBorder,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : unselectedText,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showDelete)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onDeleteRef,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.20)
                          : deleteBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.9)
                          : deleteIconColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  final result =
      await showModalBottomSheet<RecordEntry>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              void safeSetModalState(VoidCallback fn) {
                if (isClosing) return;
                if (!context.mounted) return;
                setModalState(fn);
              }

              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final sheetColor = theme.scaffoldBackgroundColor;
              final pickerBackground = isDark
                  ? theme.colorScheme.surface
                  : const Color(0xFFF8F9FB);
              final mutedSurface = isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : const Color(0xFFF3F4F6);
              final softSurface = isDark
                  ? theme.colorScheme.surface
                  : const Color(0xFFF9FAFB);
              final borderColor = isDark
                  ? theme.dividerColor
                  : const Color(0xFFE5E7EB);
              final iconColor = theme.colorScheme.onSurfaceVariant;

              final planItemsLive = categoryVM.planItems;

              if (committedRef.isEmpty && localRef.isEmpty) {
                committedRef = List<RefCategoryItem>.from(categoryVM.refItems);
                localRef = List<RefCategoryItem>.from(committedRef);
              }

              final selectedDate = categoryVM.selectedDate;
              final isToday = isSameDay(selectedDate, DateTime.now());
              final settingsEnabled = isToday;

              Future<void> commitEditChanges() async {
                for (final k in pendingRemoveKeys) {
                  await categoryVM.removeRefByKey(k);
                }
                pendingRemoveKeys.clear();

                await categoryVM.reorderRefByKeys(
                  localRef.map((e) => e.categoryKey).toList(),
                );

                committedRef = List<RefCategoryItem>.from(localRef);
              }

              Future<void> onSettingsTap() async {
                if (!isToday) {
                  showSheetToast(context, '카테고리 편집은 오늘 날짜에서만 가능해요.');
                  return;
                }

                final nav = Navigator.of(context, rootNavigator: true);
                await nav.pushNamed('/category_edit');
                if (!context.mounted) return;

                await categoryVM.initForDate(categoryVM.selectedDate);

                safeSetModalState(() {
                  committedRef = List<RefCategoryItem>.from(
                    categoryVM.refItems,
                  );
                  localRef = List<RefCategoryItem>.from(committedRef);
                  pendingRemoveKeys.clear();
                  editMode = false;
                  closeAddUI();
                });
              }

              Widget buildPlanGrid(double width) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: planItemsLive.map((item) {
                    final selected =
                        ((entry['categoryKey'] as String?) ?? '') ==
                        item.categoryKey;

                    return buildCategoryChip(
                      name: item.name,
                      emoji: item.emoji,
                      selected: selected,
                      width: width,
                      onTap: () {
                        if (editMode) return;
                        safeSetModalState(() {
                          entry['category'] = item.name;
                          entry['categoryKey'] = item.categoryKey;
                          entry['categorySource'] = 'plan';
                          entry['categoryEmoji'] = item.emoji;
                          showCategoryPicker = false;
                          showAdd = false;
                          showEmojiPicker = false;
                        });
                      },
                    );
                  }).toList(),
                );
              }

              Widget buildRefGrid(double width) {
                const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 60,
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: editMode
                      ? DragGrid<RefCategoryItem>(
                          itemList: localRef,
                          itemKey: (item) => ValueKey(item.categoryKey),
                          reorderableKey: const ValueKey(
                            'inline_ref_grid_edit',
                          ),
                          sliverGridDelegate: gridDelegate,
                          enableLongPress: true,
                          longPressDelay: Duration.zero,
                          onReorder: (newList) {
                            safeSetModalState(() {
                              localRef = List<RefCategoryItem>.from(newList);
                            });
                          },
                          itemBuilder: (context, item, index) {
                            final selected =
                                ((entry['categoryKey'] as String?) ?? '') ==
                                item.categoryKey;

                            return buildCategoryChip(
                              name: item.name,
                              emoji: item.emoji,
                              selected: selected,
                              width: width,
                              onTap: () {
                                if (editMode) return;
                                safeSetModalState(() {
                                  entry['category'] = item.name;
                                  entry['categoryKey'] = item.categoryKey;
                                  entry['categorySource'] = 'ref';
                                  entry['categoryEmoji'] = item.emoji;
                                  showCategoryPicker = false;
                                  showAdd = false;
                                  showEmojiPicker = false;
                                });
                              },
                              onDeleteRef: () {
                                safeSetModalState(() {
                                  pendingRemoveKeys.add(item.categoryKey);
                                  localRef.removeWhere(
                                    (e) => e.categoryKey == item.categoryKey,
                                  );
                                });
                              },
                            );
                          },
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: gridDelegate,
                          itemCount: localRef.length,
                          itemBuilder: (context, index) {
                            final item = localRef[index];
                            final selected =
                                ((entry['categoryKey'] as String?) ?? '') ==
                                item.categoryKey;

                            return buildCategoryChip(
                              name: item.name,
                              emoji: item.emoji,
                              selected: selected,
                              width: width,
                              onTap: () {
                                safeSetModalState(() {
                                  entry['category'] = item.name;
                                  entry['categoryKey'] = item.categoryKey;
                                  entry['categorySource'] = 'ref';
                                  entry['categoryEmoji'] = item.emoji;
                                  showCategoryPicker = false;
                                  showAdd = false;
                                  showEmojiPicker = false;
                                });
                              },
                              onDeleteRef: editMode
                                  ? () {
                                      safeSetModalState(() {
                                        pendingRemoveKeys.add(item.categoryKey);
                                        localRef.removeWhere(
                                          (e) =>
                                              e.categoryKey == item.categoryKey,
                                        );
                                      });
                                    }
                                  : null,
                            );
                          },
                        ),
                );
              }

              Widget buildInlineCategoryPicker() {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chipWidth = (constraints.maxWidth - 8 * 3) / 4;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: pickerBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TwoOptionToggle(
                                labels: const ['플랜', '참고'],
                                selected: isPlanTab ? '플랜' : '참고',
                                onChanged: (v) async {
                                  final nextIsPlan = (v == '플랜');

                                  if (!isPlanTab &&
                                      editMode &&
                                      hasUnsavedEditChanges()) {
                                    final discard = await confirmDiscardDialog(
                                      context,
                                    );
                                    if (!discard) return;
                                    safeSetModalState(
                                      () => cancelEditChanges(),
                                    );
                                  }

                                  safeSetModalState(() {
                                    isPlanTab = nextIsPlan;
                                    if (isPlanTab) {
                                      editMode = false;
                                      closeAddUI();
                                    }
                                  });
                                },
                                width: 140,
                                height: 30,
                              ),
                              Row(
                                children: [
                                  if (!isPlanTab && editMode)
                                    GestureDetector(
                                      onTap: () async {
                                        await commitEditChanges();
                                        if (!context.mounted) return;
                                        safeSetModalState(() {
                                          editMode = false;
                                          closeAddUI();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: mutedSurface,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check,
                                              size: 14,
                                              color: iconColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '편집 완료',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: iconColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (!isPlanTab) ...[
                                    GestureDetector(
                                      onTap: () {
                                        safeSetModalState(() {
                                          showAdd = !showAdd;
                                          if (showAdd) {
                                            tempNameCtrl.clear();
                                            selectedEmoji = '💰';
                                            showEmojiPicker = false;
                                          } else {
                                            showEmojiPicker = false;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: showAdd
                                              ? (isDark
                                                    ? theme
                                                          .colorScheme
                                                          .surfaceContainerHighest
                                                    : const Color(0xFFD1D5DB))
                                              : mutedSurface,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: showAdd
                                                ? (isDark
                                                      ? theme.dividerColor
                                                      : const Color(0xFF9CA3AF))
                                                : borderColor,
                                          ),
                                        ),
                                        child: Icon(
                                          showAdd ? Icons.close : Icons.add,
                                          size: 16,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Opacity(
                                    opacity: settingsEnabled ? 1 : 0.35,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: settingsEnabled
                                          ? onSettingsTap
                                          : () => showSheetToast(
                                              context,
                                              '카테고리 편집은 오늘 날짜에서만 가능해요.',
                                            ),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: mutedSurface,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: borderColor,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.settings,
                                          size: 16,
                                          color: iconColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (isPlanTab)
                            buildPlanGrid(chipWidth)
                          else
                            buildRefGrid(chipWidth),
                          if (!isPlanTab && showAdd) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => safeSetModalState(
                                    () => showEmojiPicker = !showEmojiPicker,
                                  ),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: mutedSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Center(
                                      child: Text(
                                        selectedEmoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 60,
                                    child: CustomTextField(
                                      controller: tempNameCtrl,
                                      hintText: '새 참고 카테고리 이름',
                                      onChanged: (_) =>
                                          safeSetModalState(() {}),
                                      height: 60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (showEmojiPicker) ...[
                              const SizedBox(height: 12),
                              Container(
                                height: 120,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: softSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 8,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                  itemCount: recordExpenseEmojis.length,
                                  itemBuilder: (context, index) {
                                    final emoji = recordExpenseEmojis[index];
                                    return GestureDetector(
                                      onTap: () => safeSetModalState(() {
                                        selectedEmoji = emoji;
                                        showEmojiPicker = false;
                                      }),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedEmoji == emoji
                                              ? AppColors.primary.withValues(
                                                  alpha: isDark ? 0.16 : 0.1,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: selectedEmoji == emoji
                                                  ? AppColors.primary
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: tempNameCtrl.text.trim().isEmpty
                                    ? null
                                    : () async {
                                        final name = tempNameCtrl.text.trim();

                                        final dupInPlan = planItemsLive.any(
                                          (e) => e.name == name,
                                        );
                                        final dupInRef = localRef.any(
                                          (e) => e.name == name,
                                        );

                                        if (dupInPlan || dupInRef) return;

                                        final created = await categoryVM.addRef(
                                          name: name,
                                          emoji: selectedEmoji,
                                        );

                                        if (created == null) return;

                                        safeSetModalState(() {
                                          localRef.add(created);
                                          committedRef =
                                              List<RefCategoryItem>.from(
                                                localRef,
                                              );
                                          closeAddUI();
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '참고 카테고리 추가',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              }

              return PopScope(
                canPop: !hasUnsavedEditChanges(),
                onPopInvokedWithResult: (didPop, _) async {
                  if (didPop) {
                    isClosing = true;
                    FocusManager.instance.primaryFocus?.unfocus();
                    return;
                  }

                  if (!hasUnsavedEditChanges()) return;

                  final discard = await confirmDiscardDialog(context);
                  if (!discard || !context.mounted) return;

                  safeSetModalState(() => cancelEditChanges());
                  isClosing = true;
                  FocusManager.instance.primaryFocus?.unfocus();
                  Navigator.of(context).pop();
                },
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: sheetColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SpendingInputEntry(
                              entry: entry,
                              onDelete: () {},
                              enableDismissible: false,
                              showBottomDivider: true,
                              onChanged: () => safeSetModalState(() {}),
                              onCategoryTapOverride: () {
                                safeSetModalState(() {
                                  showCategoryPicker = !showCategoryPicker;
                                  if (!showCategoryPicker) {
                                    if (hasUnsavedEditChanges()) {
                                      cancelEditChanges();
                                    } else {
                                      editMode = false;
                                      closeAddUI();
                                    }
                                  }
                                });
                              },
                              inlineCategoryPicker: showCategoryPicker
                                  ? buildInlineCategoryPicker()
                                  : null,
                              planItemsOverride: planItemsLive,
                              refItemsOverride: localRef,
                              categoryLoadingOverride: categoryVM.loading,
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: buttonText,
                              height: 56,
                              enabled: canSubmit(),
                              onPressed: () {
                                if (!canSubmit()) return;

                                isClosing = true;
                                FocusManager.instance.primaryFocus?.unfocus();

                                final result = RecordEntry(
                                  id: originEntryId,
                                  categoryKey:
                                      ((entry['categoryKey'] as String?) ?? '')
                                          .trim(),
                                  category:
                                      ((entry['category'] as String?) ?? '')
                                          .trim(),
                                  amount:
                                      ((entry['amount'] as num?)?.toDouble() ??
                                      0.0),
                                  note: ((entry['note'] as String?) ?? '')
                                      .trim(),
                                );

                                Navigator.of(context).pop(result);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        isClosing = true;
        FocusManager.instance.primaryFocus?.unfocus();
      });

  await _waitForSpendingSheetDismissed();
  tempNameCtrl.dispose();

  return result;
}

Map<String, dynamic> _createSpendingTempEntry({
  String category = '',
  String categoryKey = '',
  double amount = 0,
  String note = '',
}) {
  final amountController = TextEditingController(
    text: amount > 0 ? amount.toInt().toString() : '',
  );
  final noteController = TextEditingController(text: note);

  final entry = <String, dynamic>{
    'id': 'temp_spending',
    'categoryKey': categoryKey,
    'category': category,
    'categorySource': null,
    'categoryEmoji': null,
    'amountController': amountController,
    'noteController': noteController,
    'amount': amount,
    'note': note,
  };

  noteController.addListener(() {
    entry['note'] = noteController.text;
  });

  return entry;
}

void _disposeTempEntry(Map<String, dynamic> entry) {
  (entry['amountController'] as TextEditingController?)?.dispose();
  (entry['noteController'] as TextEditingController?)?.dispose();
}
