import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

import '../../../../../model/category/ref_category_item.dart';
import '../../../../../model/record/record_entry.dart';
import '../../../../../view_model/category/add_income_category_view_model.dart';
import '../drag_grid.dart';
import '../addIncome_widget/add_income_input_entry.dart';

const _incomeSheetDismissDelay = Duration(milliseconds: 320);

Future<void> _waitForIncomeSheetDismissed() async {
  await WidgetsBinding.instance.endOfFrame;
  await Future<void>.delayed(_incomeSheetDismissDelay);
}

const List<String> recordIncomeEmojis = [
  '💰',
  '💵',
  '💸',
  '🏦',
  '💳',
  '📈',
  '📊',
  '🪙',
  '🎁',
  '🧾',
  '💼',
  '🏢',
  '🛒',
  '🚗',
  '🏠',
  '📚',
  '🖥️',
  '📱',
  '🎉',
  '❤️',
  '⭐',
  '🔥',
  '🌱',
  '🍀',
  '☕',
  '🍽️',
  '✈️',
  '🎬',
  '🎵',
  '🛍️',
  '📦',
  '🔧',
];

Future<RecordEntry?> showTodayRecordAddIncomeBottomSheet({
  required BuildContext context,
}) async {
  final tempEntry = _createIncomeTempEntry();

  final result = await _showIncomeEntryBottomSheet(
    context: context,
    title: '수입 추가하기',
    originEntryId: 'temp_income',
    entry: tempEntry,
    buttonText: '추가',
  );

  _disposeTempEntry(tempEntry);
  return result;
}

Future<RecordEntry?> showTodayRecordEditIncomeBottomSheet({
  required BuildContext context,
  required RecordEntry entry,
}) async {
  final tempEntry = _createIncomeTempEntry(
    category: entry.category,
    categoryKey: entry.categoryKey,
    amount: entry.amount,
    note: entry.note,
  );

  final result = await _showIncomeEntryBottomSheet(
    context: context,
    title: '수입 수정',
    originEntryId: entry.id,
    entry: tempEntry,
    buttonText: '수정',
  );

  _disposeTempEntry(tempEntry);
  return result;
}

Future<RecordEntry?> _showIncomeEntryBottomSheet({
  required BuildContext context,
  required String title,
  required String originEntryId,
  required Map<String, dynamic> entry,
  required String buttonText,
}) async {
  bool isClosing = false;
  final categoryVM = context.read<AddIncomeCategoryViewModel>();

  bool canSubmit() {
    final categoryKey = ((entry['categoryKey'] as String?) ?? '').trim();
    final amount = ((entry['amount'] as num?)?.toDouble() ?? 0.0);
    return categoryKey.isNotEmpty && amount > 0;
  }

  bool showCategoryPicker = false;

  var committedRef = <RefCategoryItem>[];
  var localRef = <RefCategoryItem>[];
  final pendingRemoveKeys = <String>{};

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

  Widget buildCategoryChip({
    required String name,
    required String emoji,
    required bool selected,
    required double width,
    required VoidCallback onTap,
    VoidCallback? onDeleteRef,
  }) {
    final showDelete = editMode && onDeleteRef != null;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () {
          enterEditMode();
        },
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
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
                        color: selected
                            ? Colors.white
                            : const Color(0xFF111827),
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
                          ? Colors.white.withOpacity(0.20)
                          : Colors.black.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: selected
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF9CA3AF),
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

              if (committedRef.isEmpty && localRef.isEmpty) {
                committedRef = List<RefCategoryItem>.from(categoryVM.refItems);
                localRef = List<RefCategoryItem>.from(committedRef);
              }

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

              Widget buildRefGrid(double width) {
                const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 64,
                );

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: editMode
                      ? DragGrid<RefCategoryItem>(
                          itemList: localRef,
                          itemKey: (item) => ValueKey(item.categoryKey),
                          reorderableKey: const ValueKey(
                            'inline_income_ref_grid_edit',
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
                        color: const Color(0xFFF8F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (editMode)
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
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          '편집 완료',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                        ? const Color(0xFFD1D5DB)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: showAdd
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Icon(
                                    showAdd ? Icons.close : Icons.add,
                                    size: 16,
                                    color: showAdd
                                        ? const Color(0xFF374151)
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          buildRefGrid(chipWidth),
                          if (showAdd) ...[
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
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
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
                                      hintText: '새 수입 카테고리 이름',
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
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 8,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                  itemCount: recordIncomeEmojis.length,
                                  itemBuilder: (context, index) {
                                    final emoji = recordIncomeEmojis[index];
                                    return GestureDetector(
                                      onTap: () => safeSetModalState(() {
                                        selectedEmoji = emoji;
                                        showEmojiPicker = false;
                                      }),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: selectedEmoji == emoji
                                              ? AppColors.primary.withOpacity(
                                                  0.1,
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
                                        final dupInRef = localRef.any(
                                          (e) => e.name == name,
                                        );

                                        if (dupInRef) return;

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
                                  '수입 카테고리 추가',
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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
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
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AddIncomeInputEntry(
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

  await _waitForIncomeSheetDismissed();
  tempNameCtrl.dispose();

  return result;
}

Map<String, dynamic> _createIncomeTempEntry({
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
    'id': 'temp_income',
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
