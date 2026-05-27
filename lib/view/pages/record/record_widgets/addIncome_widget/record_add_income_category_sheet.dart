import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../component/theme/app_colors.dart';
import '../../../../../component/inputs/custom_text_field.dart';
import '../../../../../model/category/ref_category_item.dart';
import '../../../../../view_model/category/add_income_category_view_model.dart';
import '../drag_grid.dart';

class RecordAddIncomeCategoryPick {
  final String name;
  final String key;
  final String emoji;
  final String source; // 'ref'

  const RecordAddIncomeCategoryPick({
    required this.name,
    required this.key,
    required this.emoji,
    required this.source,
  });
}

final List<String> recordIncomeEmojis = [
  '💰',
  '💸',
  '💵',
  '💶',
  '💷',
  '💴',
  '🪙',
  '💳',
  '🏦',
  '📈',
  '💼',
  '🏢',
  '🎁',
  '🎓',
  '↩️',
  '🛍️',
  '📦',
  '🏆',
  '🎉',
  '📊',
  '📁',
  '🧾',
  '🪪',
  '🧮',
  '💎',
  '🏠',
  '🏡',
  '🚗',
  '📱',
  '🖥️',
];

Future<RecordAddIncomeCategoryPick?> openRecordAddIncomeCategorySheet(
  BuildContext context, {
  required List<RefCategoryItem> refItems,
  Future<RefCategoryItem?> Function(String name, String emoji)? onAddRef,
  Future<void> Function(String categoryKey)? onRemoveRef,
  Future<void> Function(List<String> newOrderKeys)? onReorderRef,
  String? selectedName,
  String? selectedKey,
}) async {
  var committedRef = List<RefCategoryItem>.from(refItems);
  var localRef = List<RefCategoryItem>.from(committedRef);
  final pendingRemoveKeys = <String>{};

  bool editMode = false;
  bool showAdd = false;
  bool showEmojiPicker = false;

  String selectedEmoji = '💰';
  final tempNameCtrl = TextEditingController();

  RecordAddIncomeCategoryPick? result;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SizedBox(
        width: double.infinity,
        child: StatefulBuilder(
          builder: (context, setModalState) {
            ctx.watch<AddIncomeCategoryViewModel>();
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final chipSurface = isDark
                ? AppColors.darkSurface
                : const Color(0xFFF3F4F6);
            final chipBorder = isDark
                ? AppColors.darkBorder
                : const Color(0xFFE5E7EB);
            final subtleSurface = isDark
                ? const Color(0xFF181818)
                : const Color(0xFFF9FAFB);
            final mutedButtonSurface = isDark
                ? const Color(0xFF242424)
                : const Color(0xFFF3F4F6);
            final activeMutedButtonSurface = isDark
                ? const Color(0xFF303030)
                : const Color(0xFFD1D5DB);
            final iconMutedColor = isDark
                ? AppColors.darkSubText
                : const Color(0xFF6B7280);
            final textColor = theme.colorScheme.onSurface;

            void closeAddUI() {
              showAdd = false;
              showEmojiPicker = false;
              tempNameCtrl.clear();
              selectedEmoji = '💰';
            }

            void cancelEditChanges() {
              localRef = List<RefCategoryItem>.from(committedRef);
              pendingRemoveKeys.clear();
              editMode = false;
              closeAddUI();
            }

            Future<void> commitEditChanges() async {
              if (onRemoveRef != null) {
                for (final k in pendingRemoveKeys) {
                  await onRemoveRef!(k);
                }
              }
              pendingRemoveKeys.clear();

              if (onReorderRef != null) {
                await onReorderRef!(
                  localRef.map((e) => e.categoryKey).toList(),
                );
              }

              committedRef = List<RefCategoryItem>.from(localRef);
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

            Future<bool> confirmDiscardDialog() async {
              final res = await showDialog<bool>(
                context: ctx,
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

            bool isSelectedItem({required String key, required String name}) {
              if (selectedKey != null && selectedKey!.isNotEmpty) {
                return selectedKey == key;
              }
              return (selectedName ?? '') == name;
            }

            Widget chipBody({
              required String name,
              required String emoji,
              required bool selected,
              VoidCallback? onDeleteRef,
              double height = 60,
            }) {
              final showDelete = editMode && onDeleteRef != null;

              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: height,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : chipSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.primary : chipBorder,
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
                              color: selected ? Colors.white : textColor,
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
                                : textColor.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.9)
                                : iconMutedColor,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }

            Widget refGridItem(RefCategoryItem item, int index) {
              final selected = isSelectedItem(
                key: item.categoryKey,
                name: item.name,
              );

              return GestureDetector(
                onTap: () {
                  if (editMode) return;
                  result = RecordAddIncomeCategoryPick(
                    name: item.name,
                    key: item.categoryKey,
                    emoji: item.emoji,
                    source: 'ref',
                  );
                  Navigator.pop(ctx);
                },
                onLongPress: () {
                  setModalState(() {
                    editMode = true;
                    closeAddUI();
                  });
                },
                child: chipBody(
                  name: item.name,
                  emoji: item.emoji,
                  selected: selected,
                  height: 60,
                  onDeleteRef: editMode
                      ? () {
                          setModalState(() {
                            pendingRemoveKeys.add(item.categoryKey);
                            localRef.removeWhere(
                              (e) => e.categoryKey == item.categoryKey,
                            );
                          });
                        }
                      : null,
                ),
              );
            }

            void toggleAdd() {
              setModalState(() {
                showAdd = !showAdd;
                if (showAdd) {
                  tempNameCtrl.clear();
                  selectedEmoji = '💰';
                  showEmojiPicker = false;
                } else {
                  showEmojiPicker = false;
                }
              });
            }

            Widget buildRefGrid() {
              const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 60,
              );

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: editMode
                    ? DragGrid<RefCategoryItem>(
                        itemList: localRef,
                        itemKey: (item) => ValueKey(item.categoryKey),
                        reorderableKey: const ValueKey('income_ref_grid_edit'),
                        sliverGridDelegate: gridDelegate,
                        enableLongPress: true,
                        longPressDelay: Duration.zero,
                        onReorder: (newList) {
                          setModalState(() {
                            localRef = List<RefCategoryItem>.from(newList);
                          });
                        },
                        itemBuilder: (context, item, index) =>
                            refGridItem(item, index),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: gridDelegate,
                        itemCount: localRef.length,
                        itemBuilder: (context, index) =>
                            refGridItem(localRef[index], index),
                      ),
              );
            }

            return WillPopScope(
              onWillPop: () async {
                if (hasUnsavedEditChanges()) {
                  final discard = await confirmDiscardDialog();
                  if (!discard) return false;

                  setModalState(cancelEditChanges);
                  return true;
                }
                return true;
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '수입 카테고리',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            if (editMode)
                              GestureDetector(
                                onTap: () async {
                                  await commitEditChanges();
                                  if (!ctx.mounted) return;
                                  setModalState(() {
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
                                    color: mutedButtonSurface,
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
                              onTap: toggleAdd,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: showAdd
                                      ? activeMutedButtonSurface
                                      : mutedButtonSurface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: showAdd
                                        ? theme.colorScheme.onSurfaceVariant
                                        : chipBorder,
                                  ),
                                ),
                                child: Icon(
                                  showAdd ? Icons.close : Icons.add,
                                  size: 16,
                                  color: showAdd
                                      ? theme.colorScheme.onSurface
                                      : iconMutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    buildRefGrid(),
                    const SizedBox(height: 16),

                    if (showAdd) ...[
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setModalState(() {
                              showEmojiPicker = !showEmojiPicker;
                            }),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: mutedButtonSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: chipBorder),
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
                                onChanged: (_) => setModalState(() {}),
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
                            color: subtleSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: chipBorder),
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
                                onTap: () => setModalState(() {
                                  selectedEmoji = emoji;
                                  showEmojiPicker = false;
                                }),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selectedEmoji == emoji
                                        ? AppColors.primary.withValues(
                                            alpha: 0.16,
                                          )
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
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

                                  final created = await onAddRef?.call(
                                    name,
                                    selectedEmoji,
                                  );
                                  if (created == null) return;

                                  setModalState(() {
                                    localRef.add(created);
                                    committedRef = List<RefCategoryItem>.from(
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

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );

  tempNameCtrl.dispose();
  return result;
}
