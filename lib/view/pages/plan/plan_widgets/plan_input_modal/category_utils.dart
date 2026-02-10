import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

/// =======================
///  CategoryPill (왼쪽 칩) - 프리셋 없음
/// =======================
class CategoryPill extends StatelessWidget {
  final String text;
  final String emoji;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final double height;

  final bool highlight;
  final Color highlightColor;

  const CategoryPill({
    super.key,
    required this.text,
    required this.emoji,
    required this.onTap,
    required this.onClear,
    this.height = 60,
    this.highlight = false,
    this.highlightColor = const Color(0xFFFFF1F1),
  });

  @override
  Widget build(BuildContext context) {
    final name = text.trim();
    final hasValue = name.isNotEmpty;

    final Color bgColor = (hasValue && highlight)
        ? highlightColor
        : (hasValue ? AppColors.lightBlue : AppColors.greyBackground);

    final Color textColor = hasValue ? Colors.black : AppColors.subText;

    final displayEmoji = (emoji.trim().isNotEmpty) ? emoji : '💰';

    return InkWell(
      onTap: onTap,
      onLongPress: onClear,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (!hasValue)
              Icon(Icons.add, size: 18, color: AppColors.subText)
            else
              Text(displayEmoji, style: const TextStyle(fontSize: 16)),

            const SizedBox(width: 6),
            Expanded(
              child: Text(
                hasValue ? name : '입력',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
///  소비 이모지 리스트
/// =======================
final List<String> expenseEmojis = [
  '💰','💸','💳','🏦','💵','💶','💷','💴','🪙','💎',
  '🍕','🍔','🍟','🌭','🥪','🌮','🌯','🥙','🍱','🍜',
  '☕','🥤','🧋','🍵','🍶','🍷','🍸','🍹','🍺','🍻',
  '🛍️','🛒','💍','👕','👖','👗','👠','👟','🎒','👜',
  '🎬','🎮','🎯','🎲','🎪','🎨','🎭','🎡','🎠',
  '🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐',
  '✈️','🚁','🚀','🛸','🚢','⛵','🚤','🛥️','🚂',
  '🏠','🏡','🏢','🏬','🏪','🏫','🏩','🏨','🏛️',
  '💊','🏥','⚕️','🩺','💉','🧬','🦠','🧪','🧫','🧼',
  '📱','💻','⌨️','🖥️','🖨️','📠','📞','☎️','📺','📻',
  '🏋️','🤸','🧘','🏊','🚴','🏃','⚽','🏀','🏈','🎾',
  '📚','✏️','📝','📋','📊','📈','📉','💼','🗂️','📁',
  '🎁','🎂','🍰','🧁','🍭','🍬','🍫','🍩','🍪','🥧',
  '🌱','🌿','🌾','🌻','🌺','🌸','🌼','🌷','🌹','🥀',
  '🐕','🐈','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯',
];

/// =======================
///  새 카테고리 선택 바텀시트
///  - 프리셋/커스텀 구분 없음
///  - 한 줄 4개
///  - 추가 버튼으로 칩 생성
/// =======================
Future<void> openCategorySheet(
    BuildContext context,
    TextEditingController controller,
    void Function(String) onSelected, {
      required List<String> categories,
      required Map<String, String> categoryEmojis,

      /// ✅ 중복 선택 방지용
      required Set<String> alreadySelectedNames,
      String? currentSelectedName,

      void Function(String name, String emoji)? onSelectedWithEmoji,
      void Function(String name, String emoji)? onCategoryAdded,
      void Function(String name)? onCategoryRemoved,
      void Function(List<String> newOrder)? onReorder,
    }) async {
  String temp = controller.text;
  TextEditingController? tempController;

  // 로컬 복사본
  List<String> localCategories = [...categories];
  Map<String, String> localEmojis = Map<String, String>.from(categoryEmojis);

  bool isEditMode = false;
  bool showAddForm = false;
  bool showEmojiPicker = false;
  String selectedEmoji = '💰';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          String? inlineError;
          Timer? inlineErrorTimer;

          void showInlineError(String msg) {
            inlineErrorTimer?.cancel();
            setModalState(() => inlineError = msg);
            inlineErrorTimer = Timer(const Duration(seconds: 2), () {
              if (Navigator.of(ctx).canPop()) {
                setModalState(() => inlineError = null);
              }
            });
          }

          void clearInlineError() {
            inlineErrorTimer?.cancel();
            setModalState(() => inlineError = null);
          }

          void exitEditModeAndNotify() {
            if (onReorder != null) onReorder(localCategories);
            setModalState(() => isEditMode = false);
          }

          Widget buildChipContent(String name, bool selected) {
            final emoji = (localEmojis[name]?.trim().isNotEmpty ?? false)
                ? localEmojis[name]!
                : '💰';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }

          Widget buildCategoryGrid() {
            return LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 8.0;
                final double chipWidth =
                    (constraints.maxWidth - spacing * 3) / 4;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: localCategories.asMap().entries.map((entry) {
                    final index = entry.key;
                    final name = entry.value;
                    final bool selected = temp == name;

                    return SizedBox(
                      width: chipWidth,
                      child: Draggable<String>(
                        data: name,
                        onDragStarted: () => setModalState(() => isEditMode = true),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: buildChipContent(name, true),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: buildChipContent(name, false),
                          ),
                        ),
                        child: DragTarget<String>(
                          onWillAcceptWithDetails: (details) => details.data != name,
                          onAcceptWithDetails: (details) {
                            setModalState(() {
                              final dragged = details.data;
                              final oldIndex = localCategories.indexOf(dragged);
                              final newIndex = index;

                              if (oldIndex != -1 && oldIndex != newIndex) {
                                final item = localCategories.removeAt(oldIndex);
                                localCategories.insert(newIndex, item);
                              }
                              isEditMode = true;
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return GestureDetector(
                              onTap: () {
                                if (isEditMode) return;

                                final picked = name.trim();
                                final current = (currentSelectedName ?? '').trim();

                                final isDuplicate =
                                    alreadySelectedNames.contains(picked) &&
                                        picked != current;

                                if (isDuplicate) {
                                  showInlineError('이미 선택된 카테고리입니다.');
                                  return;
                                }

                                final emoji =
                                (localEmojis[picked]?.trim().isNotEmpty ?? false)
                                    ? localEmojis[picked]!
                                    : '💰';

                                setModalState(() {
                                  localEmojis[picked] = emoji;
                                  temp = picked;
                                  tempController?.text = temp;
                                });

                                controller.text = picked;
                                onSelected(picked);
                                onSelectedWithEmoji?.call(picked, emoji);

                                clearInlineError();
                                Navigator.pop(ctx);
                              },
                              onLongPress: () => setModalState(() => isEditMode = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Expanded(child: buildChipContent(name, selected)),
                                    if (isEditMode) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            localCategories.remove(name);
                                            localEmojis.remove(name);
                                            onCategoryRemoved?.call(name);

                                            if (temp == name) {
                                              temp = '';
                                              tempController?.text = '';
                                            }
                                            if (localCategories.isEmpty) {
                                              isEditMode = false;
                                            }
                                          });
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: selected
                                              ? Colors.white.withOpacity(0.8)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }

          return Padding(
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
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '카테고리 선택',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          Row(
                            children: [
                              if (isEditMode)
                                GestureDetector(
                                  onTap: exitEditModeAndNotify,
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
                                    child: Row(
                                      children: const [
                                        Icon(Icons.check, size: 14),
                                        SizedBox(width: 4),
                                        Text('편집 완료', style: TextStyle(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    showAddForm = !showAddForm;
                                    if (showAddForm) {
                                      tempController?.clear();
                                      temp = '';
                                      selectedEmoji = '💰';
                                      clearInlineError();
                                    }
                                  });
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: showAddForm
                                        ? AppColors.primary
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: showAddForm
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Icon(
                                    showAddForm ? Icons.close : Icons.add,
                                    size: 16,
                                    color: showAddForm
                                        ? Colors.white
                                        : const Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (isEditMode) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  '편집 모드: 칩을 드래그해 순서를 바꾸거나 X 버튼으로 삭제할 수 있어요.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF1F2933),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      buildCategoryGrid(),

                      if (inlineError != null) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            inlineError!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      if (showAddForm) ...[
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setModalState(() => showEmojiPicker = !showEmojiPicker),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Center(
                                  child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: Builder(
                                  builder: (context) {
                                    tempController ??= TextEditingController(text: temp);
                                    return CustomTextField(
                                      controller: tempController!,
                                      hintText: '새 카테고리 이름',
                                      onChanged: (v) => setModalState(() => temp = v),
                                      height: 60,
                                    );
                                  },
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
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                crossAxisSpacing: 4,
                                mainAxisSpacing: 4,
                              ),
                              itemCount: expenseEmojis.length,
                              itemBuilder: (context, index) {
                                final emoji = expenseEmojis[index];
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedEmoji = emoji;
                                      showEmojiPicker = false;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selectedEmoji == emoji
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: selectedEmoji == emoji ? AppColors.primary : null,
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
                            onPressed: temp.trim().isNotEmpty
                                ? () {
                              final name = temp.trim();
                              final current = (currentSelectedName ?? '').trim();

                              if (localCategories.contains(name)) {
                                showInlineError('이미 있는 카테고리 이름이에요.');
                                return;
                              }

                              final dupSelected =
                                  alreadySelectedNames.contains(name) && name != current;
                              if (dupSelected) {
                                showInlineError('이미 선택된 카테고리입니다.');
                                return;
                              }

                              setModalState(() {
                                localCategories.add(name);
                                localEmojis[name] = selectedEmoji;
                              });

                              onCategoryAdded?.call(name, selectedEmoji);

                              setModalState(() {
                                temp = '';
                                tempController?.clear();
                                selectedEmoji = '💰';
                              });

                              clearInlineError();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '추가',
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
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    },
  );
}
