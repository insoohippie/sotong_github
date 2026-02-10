import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

import '../../../../model/category/category_edit_item.dart';   // CategoryEditItem, CategoryKind
import '../../../../model/category/ref_category_item.dart';   // RefCategoryItem

class SpendingCategoryPick {
  final String name;
  final String key;     // ✅ categoryKey로 저장할 값
  final String emoji;
  final String source;  // 'plan' | 'ref'
  const SpendingCategoryPick({
    required this.name,
    required this.key,
    required this.emoji,
    required this.source,
  });
}

final List<String> expenseEmojis = [
  '💰','💸','💳','🏦','💵','💶','💷','💴','🪙','💎',
  '🍕','🍔','🍟','🌭','🥪','🌮','🌯','🥙','🍱','🍜',
  '☕','🥤','🧋','🍵','🍶','🍷','🍸','🍹','🍺','🍻',
  '🛍️','🛒','💍','👕','👖','👗','👠','👟','🎒','👜',
  '🎬','🎮','🎯','🎲','🎪','🎨','🎭','🎪','🎡','🎠',
  '🚗','🚕','🚙','🚌','🚎','🏎️','🚓','🚑','🚒','🚐',
  '✈️','🚁','🚀','🛸','🚢','⛵','🚤','🛥️','🚁','🚂',
  '🏠','🏡','🏢','🏬','🏪','🏫','🏩','🏨','🏦','🏛️',
  '💊','🏥','⚕️','🩺','💉','🧬','🦠','🧪','🧫','🧼',
  '📱','💻','⌨️','🖥️','🖨️','📠','📞','☎️','📺','📻',
  '🏋️','🤸','🧘','🏊','🚴','🏃','⚽','🏀','🏈','🎾',
  '📚','✏️','📝','📋','📊','📈','📉','💼','🗂️','📁',
  '🎁','🎂','🍰','🧁','🍭','🍬','🍫','🍩','🍪','🥧',
  '🌱','🌿','🌾','🌻','🌺','🌸','🌼','🌷','🌹','🥀',
  '🐕','🐈','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯',
];

Future<SpendingCategoryPick?> openSpendingCategorySheetWithKey(
    BuildContext context, {
      required List<CategoryEditItem> planItems,  // kind=plan
      required List<RefCategoryItem> refItems,   // 로컬 편집 대상

      // ✅ “나중에 저장 연결할 때” 쓰는 옵션 콜백 (지금은 없어도 됨)
      void Function(String name, String emoji)? onAddRef,
      void Function(String categoryKey)? onRemoveRef,
      void Function(List<String> newOrderKeys)? onReorderRef,

      String? selectedName,
      String? selectedKey,
    }) async {
  // ref만 로컬에서 편집
  final localRef = List<RefCategoryItem>.from(refItems);

  bool editMode = false;
  bool showAdd = false;
  bool showEmojiPicker = false;

  String selectedEmoji = '💰';
  final tempNameCtrl = TextEditingController();
  SpendingCategoryPick? result;

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
          void _exitEditMode() {
            if (onReorderRef != null) {
              onReorderRef(localRef.map((e) => e.categoryKey).toList());
            }
            setModalState(() => editMode = false);
          }

          Widget _badge(String source) {
            final isPlan = source == 'plan';
            final bg = isPlan
                ? AppColors.primary.withOpacity(0.12)
                : const Color(0xFF6B7280).withOpacity(0.12);
            final fg = isPlan ? AppColors.primary : const Color(0xFF6B7280);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPlan ? '플랜' : '참고',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            );
          }

          // --------- CHIP UI 공통 ----------
          Widget _chipBody({
            required String name,
            required String emoji,
            required String source,
            required bool isFeedback,
            required bool isSelected,
            VoidCallback? onDeleteRef, // ref 편집일 때만
          }) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                ),
                boxShadow: isFeedback
                    ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
                    : null,
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _badge(source),
                  if (editMode && source == 'ref' && onDeleteRef != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDeleteRef,
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: isSelected
                            ? Colors.white.withOpacity(0.85)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          Widget _planChip(CategoryEditItem item) {
            final isSelected =
            (selectedKey != null && selectedKey!.isNotEmpty)
                ? (selectedKey == item.categoryKey)
                : (selectedName == item.name);

            final w = (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4;

            return SizedBox(
              width: w,
              child: GestureDetector(
                onTap: () {
                  if (editMode) return; // 편집 중엔 선택 막기(원하면 풀어도 됨)
                  result = SpendingCategoryPick(
                    name: item.name,
                    key: item.categoryKey,
                    emoji: item.emoji,
                    source: 'plan',
                  );
                  Navigator.pop(ctx);
                },
                child: _chipBody(
                  name: item.name,
                  emoji: item.emoji,
                  source: 'plan',
                  isFeedback: false,
                  isSelected: isSelected,
                ),
              ),
            );
          }

          Widget _refChip(RefCategoryItem item, int index) {
            final isSelected =
            (selectedKey != null && selectedKey!.isNotEmpty)
                ? (selectedKey == item.categoryKey)
                : (selectedName == item.name);

            final w = (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4;

            return SizedBox(
              width: w,
              child: Draggable<String>(
                data: item.categoryKey,
                onDragStarted: () => setModalState(() => editMode = true),
                feedback: Material(
                  color: Colors.transparent,
                  child: _chipBody(
                    name: item.name,
                    emoji: item.emoji,
                    source: 'ref',
                    isFeedback: true,
                    isSelected: isSelected,
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: _chipBody(
                    name: item.name,
                    emoji: item.emoji,
                    source: 'ref',
                    isFeedback: false,
                    isSelected: isSelected,
                  ),
                ),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                  details.data != item.categoryKey,
                  onAcceptWithDetails: (details) {
                    setModalState(() {
                      final draggedKey = details.data;
                      final oldIndex =
                      localRef.indexWhere((e) => e.categoryKey == draggedKey);
                      final newIndex = index;
                      if (oldIndex != -1 && oldIndex != newIndex) {
                        final moved = localRef.removeAt(oldIndex);
                        localRef.insert(newIndex, moved);
                      }
                      editMode = true;
                    });
                  },
                  builder: (_, __, ___) => GestureDetector(
                    onTap: () {
                      if (editMode) return; // 편집 중엔 선택 막기
                      result = SpendingCategoryPick(
                        name: item.name,
                        key: item.categoryKey,
                        emoji: item.emoji,
                        source: 'ref',
                      );
                      Navigator.pop(ctx);
                    },
                    onLongPress: () => setModalState(() => editMode = true),
                    child: _chipBody(
                      name: item.name,
                      emoji: item.emoji,
                      source: 'ref',
                      isFeedback: false,
                      isSelected: isSelected,
                      onDeleteRef: () {
                        setModalState(() {
                          localRef.removeWhere((e) => e.categoryKey == item.categoryKey);
                        });
                        onRemoveRef?.call(item.categoryKey);
                        if (localRef.isEmpty) setModalState(() => editMode = false);
                      },
                    ),
                  ),
                ),
              ),
            );
          }

          Widget _section({
            required String title,
            required String source,
            required List<Widget> chips,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _badge(source),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips,
                ),
              ],
            );
          }

          final planChips = planItems.map(_planChip).toList();
          final refChips = [
            for (int i = 0; i < localRef.length; i++) _refChip(localRef[i], i),
          ];

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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '카테고리 선택',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Row(
                      children: [
                        if (editMode)
                          GestureDetector(
                            onTap: _exitEditMode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                children: [
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
                              showAdd = !showAdd;
                              if (showAdd) {
                                tempNameCtrl.clear();
                                selectedEmoji = '💰';
                                showEmojiPicker = false;
                              }
                            });
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: showAdd ? AppColors.primary : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: showAdd ? AppColors.primary : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Icon(
                              showAdd ? Icons.close : Icons.add,
                              size: 16,
                              color: showAdd ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                if (editMode) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            '참고(REF)만 편집 가능: 드래그로 순서 변경 / X로 삭제',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1F2933)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                _section(title: '플랜 카테고리', source: 'plan', chips: planChips),
                const SizedBox(height: 16),
                _section(title: '참고 카테고리', source: 'ref', chips: refChips),

                const SizedBox(height: 16),

                if (showAdd) ...[
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
                          child: CustomTextField(
                            controller: tempNameCtrl,
                            hintText: '새 참고 카테고리 이름',
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
                            onTap: () => setModalState(() {
                              selectedEmoji = emoji;
                              showEmojiPicker = false;
                            }),
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
                      onPressed: tempNameCtrl.text.trim().isEmpty
                          ? null
                          : () {
                        final name = tempNameCtrl.text.trim();

                        // 중복 방지(plan/ref 모두)
                        final dupInPlan = planItems.any((e) => e.name == name);
                        final dupInRef = localRef.any((e) => e.name == name);
                        if (dupInPlan || dupInRef) return;

                        final key = 'ref_${DateTime.now().millisecondsSinceEpoch}';
                        setModalState(() {
                          localRef.add(
                            RefCategoryItem(
                              categoryKey: key,
                              name: name,
                              emoji: selectedEmoji,
                              order: localRef.length,
                            ),
                          );
                          tempNameCtrl.clear();
                          selectedEmoji = '💰';
                        });

                        onAddRef?.call(name, selectedEmoji);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  );

  tempNameCtrl.dispose();
  return result;
}
