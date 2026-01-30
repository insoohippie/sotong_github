import 'package:flutter/material.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import '../../../../model/category/category_snapshot_item.dart';

class SpendingCategoryPick {
  final String name;
  final String key;   // ✅ categoryKey로 저장할 값
  final String emoji;
  final String source; // 'plan' | 'ref'
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
      required List<CategorySnapshotItem> planItems,
      required List<CategorySnapshotItem> refItems,

      required void Function(String name, String emoji) onAddRef,
      required void Function(String name) onRemoveRef,
      required void Function(List<String> newOrderNames) onReorderRef,

      String? selectedName,
      String? selectedKey,
    }) async {
  // ref만 로컬 편집
  final localRef = List<CategorySnapshotItem>.from(refItems);

  bool editMode = false;
  bool showAdd = false;
  bool showEmojiPicker = false;

  String tempName = '';
  String selectedEmoji = '💰';

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
            // ✅ ref 순서 저장 콜백
            onReorderRef(localRef.map((e) => e.name).toList());
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

          Widget _chipBody(
              CategorySnapshotItem item,
              String source,
              bool isFeedback,
              bool isSelected,
              ) {
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
                  Text(item.emoji ?? '💰', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.name,
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
                  if (editMode && source == 'ref') ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setModalState(() {
                          localRef.removeWhere((e) => e.categoryId == item.categoryId);
                        });
                        onRemoveRef(item.name);
                        if (localRef.isEmpty) setModalState(() => editMode = false);
                      },
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

          Widget _chip({
            required CategorySnapshotItem item,
            required String source,
            required bool reorderable,
            required int index,
          }) {
            final isSelected =
            (selectedKey != null && selectedKey!.isNotEmpty)
                ? (selectedKey == item.categoryId)
                : (selectedName == item.name);

            return SizedBox(
              width: (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4,
              child: reorderable
                  ? Draggable<String>(
                data: item.categoryId,
                onDragStarted: () => setModalState(() => editMode = true),
                feedback: Material(
                  color: Colors.transparent,
                  child: _chipBody(item, source, true, isSelected),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.25,
                  child: _chipBody(item, source, false, isSelected),
                ),
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                  details.data != item.categoryId,
                  onAcceptWithDetails: (details) {
                    setModalState(() {
                      final draggedId = details.data;
                      final oldIndex =
                      localRef.indexWhere((e) => e.categoryId == draggedId);
                      final newIndex = index;
                      if (oldIndex != -1 && oldIndex != newIndex) {
                        final moved = localRef.removeAt(oldIndex);
                        localRef.insert(newIndex, moved);
                      }
                      editMode = true;
                    });
                  },
                  builder: (_, __, ___) =>
                      _chipBody(item, source, false, isSelected),
                ),
              )
                  : GestureDetector(
                onTap: () {
                  if (editMode && source == 'ref') return;
                  result = SpendingCategoryPick(
                    name: item.name,
                    key: item.categoryId,
                    emoji: item.emoji ?? '💰',
                    source: source,
                  );
                  Navigator.pop(ctx);
                },
                onLongPress: () {
                  if (source == 'ref') setModalState(() => editMode = true);
                },
                child: _chipBody(item, source, false, isSelected),
              ),
            );
          }



          Widget _section({
            required String title,
            required String source,
            required List<CategorySnapshotItem> items,
            required bool reorderable,
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
                  children: [
                    for (int i = 0; i < items.length; i++)
                      _chip(
                        item: items[i],
                        source: source,
                        reorderable: reorderable,
                        index: i,
                      ),
                  ],
                ),
              ],
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

                // 헤더
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
                                tempName = '';
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

                // PLAN
                _section(
                  title: '플랜 카테고리',
                  source: 'plan',
                  items: planItems,
                  reorderable: false,
                ),

                const SizedBox(height: 16),

                // REF (reorderable)
                _section(
                  title: '참고 카테고리',
                  source: 'ref',
                  items: localRef,
                  reorderable: true,
                ),

                const SizedBox(height: 16),

                // REF 추가
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
                            controller: TextEditingController(text: tempName)
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: tempName.length),
                              ),
                            hintText: '새 참고 카테고리 이름',
                            onChanged: (v) => setModalState(() => tempName = v),
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
                      onPressed: tempName.trim().isNotEmpty
                          ? () {
                        final name = tempName.trim();

                        // 중복 방지(PLAN/REF 모두)
                        final dupInPlan = planItems.any((e) => e.name == name);
                        final dupInRef  = localRef.any((e) => e.name == name);
                        if (dupInPlan || dupInRef) return;

                        // add는 VM에서 하고(키 생성), 여기서는 로컬 UI도 즉시 반영해줌
                        onAddRef(name, selectedEmoji);

                        setModalState(() {
                          // 로컬에도 즉시 추가(키는 임시로 name 기반 사용)
                          localRef.add(
                            CategorySnapshotItem(
                              categoryId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                              name: name,
                              emoji: selectedEmoji,
                              order: localRef.length,
                              dailyAmount: null,
                            ),
                          );
                          tempName = '';
                          selectedEmoji = '💰';
                        });
                      }
                          : null,
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

  return result;
}
