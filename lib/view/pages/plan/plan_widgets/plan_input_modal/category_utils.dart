import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

/// =======================
///  예전 그대로: 프리셋 + 이모지 헬퍼
/// =======================

/// 카테고리 프리셋 (다른 화면에서 쓸 수 있으니 남겨둠)
class CatPreset {
  final String name;
  final IconData icon;
  const CatPreset(this.name, this.icon);
}

const List<CatPreset> dailyPresets = [
  CatPreset('식비', Icons.restaurant_rounded),
  CatPreset('카페', Icons.local_cafe_rounded),
  CatPreset('쇼핑', Icons.shopping_bag_rounded),
  CatPreset('여가', Icons.sports_esports_rounded),
];

const List<CatPreset> incomePresets = [
  CatPreset('급여', Icons.account_balance_wallet_rounded),
  CatPreset('사업', Icons.business_center_rounded),
  CatPreset('배당', Icons.trending_up_rounded),
  CatPreset('용돈', Icons.card_giftcard_rounded),
];

const List<CatPreset> fixedPresets = [
  CatPreset('주거', Icons.home_rounded),
  CatPreset('통신', Icons.wifi_rounded),
  CatPreset('교통', Icons.directions_bus_rounded),
  CatPreset('구독', Icons.subscriptions_rounded),
];

String _getPresetEmoji(String categoryName) {
  switch (categoryName) {
    case '급여':
      return '💼';
    case '사업':
      return '🏢';
    case '배당':
      return '📈';
    case '용돈':
      return '🎁';
    case '식비':
      return '🍽️';
    case '카페':
      return '☕';
    case '쇼핑':
      return '🛍️';
    case '여가':
      return '🎮';
    case '주거':
      return '🏠';
    case '통신':
      return '📱';
    case '교통':
      return '🚌';
    case '구독':
      return '📺';
    default:
      return '💰';
  }
}

/// =======================
///  CategoryPill (왼쪽 칩)
/// =======================

class CategoryPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final double height;
  final List<CatPreset> presets;
  final String? customEmoji;

  final bool highlight;
  final Color highlightColor;

  const CategoryPill({
    Key? key,
    required this.text,
    required this.onTap,
    required this.onClear,
    required this.presets,
    this.height = 60,
    this.highlight = false,
    this.highlightColor = const Color(0xFFFFF1F1),
    this.customEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasValue = text.trim().isNotEmpty;

    final CatPreset matched = presets.firstWhere(
          (p) => p.name == text.trim(),
      orElse: () => const CatPreset('', Icons.add_circle_outline_rounded),
    );

    final bool isPreset = matched.name.isNotEmpty;
    final bool isCustomCategory =
        hasValue && !isPreset && customEmoji != null && customEmoji!.isNotEmpty;

    final Color bgColor = (hasValue && highlight)
        ? highlightColor
        : (hasValue ? AppColors.lightBlue : AppColors.greyBackground);

    final Color iconColor = hasValue ? AppColors.primary : AppColors.subText;
    final Color textColor = hasValue ? Colors.black : AppColors.subText;

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
            if (hasValue && isPreset)
              Icon(matched.icon, size: 18, color: iconColor)
            else if (isCustomCategory)
              Text(customEmoji!, style: const TextStyle(fontSize: 16))
            else
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: iconColor,
              ),
            const SizedBox(width: 6),
            Expanded(
              child: ParagraphText(
                text: hasValue ? text : '입력',
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
///  소비 이모지 리스트 (정리 버전)
/// =======================

final List<String> _expenseEmojis = [
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
      /// 전체 카테고리 이름 리스트 (프리셋+커스텀 통합)
      required List<String> categories,

      /// 카테고리별 이모지 (없으면 preset 기본 이모지 or 💰)
      required Map<String, String> categoryEmojis,

      /// 새 카테고리 추가 시 콜백 (name, emoji)
      void Function(String name, String emoji)? onCategoryAdded,

      /// 카테고리 삭제 시 콜백 (name)
      void Function(String name)? onCategoryRemoved,

      /// 순서 변경 후 콜백 (새 이름 리스트)
      void Function(List<String> newOrder)? onReorder,
    }) async {
  String temp = controller.text;
  TextEditingController? tempController;

  // 로컬 복사본 (여기서만 수정하고, 마지막에 콜백으로 전달)
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
          void _exitEditModeAndNotify() {
            if (onReorder != null) {
              onReorder(localCategories);
            }
            setModalState(() {
              isEditMode = false;
            });
          }

          Widget _buildChipContent(String name, bool selected) {
            final emoji =
                localEmojis[name] ?? _getPresetEmoji(name);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
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

          Widget _buildCategoryGrid() {
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
                        onDragStarted: () {
                          setModalState(() {
                            isEditMode = true;
                          });
                        },
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
                            child: _buildChipContent(name, true),
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
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: _buildChipContent(name, false),
                          ),
                        ),
                        child: DragTarget<String>(
                          onWillAcceptWithDetails: (details) {
                            return details.data != name;
                          },
                          onAcceptWithDetails: (details) {
                            setModalState(() {
                              final dragged = details.data;
                              final oldIndex =
                              localCategories.indexOf(dragged);
                              final newIndex = index;

                              if (oldIndex != -1 && oldIndex != newIndex) {
                                final item =
                                localCategories.removeAt(oldIndex);
                                localCategories.insert(
                                  newIndex,
                                  item,
                                );
                              }
                              isEditMode = true;
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            return GestureDetector(
                              onTap: () {
                                if (isEditMode) return;
                                setModalState(() {
                                  temp = name;
                                  tempController?.text = temp;
                                });
                                controller.text = name;
                                onSelected(name);
                                Navigator.pop(ctx);
                              },
                              onLongPress: () {
                                setModalState(() {
                                  isEditMode = true;
                                });
                              },
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
                                    Expanded(
                                      child:
                                      _buildChipContent(name, selected),
                                    ),
                                    if (isEditMode) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () {
                                          setModalState(() {
                                            localCategories.remove(name);
                                            localEmojis.remove(name);
                                            if (onCategoryRemoved != null) {
                                              onCategoryRemoved(name);
                                            }
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
                      // 헤더
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
                                  onTap: _exitEditModeAndNotify,
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
                                        Text(
                                          '편집 완료',
                                          style: TextStyle(
                                            fontSize: 11,
                                          ),
                                        ),
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
                              Icon(
                                Icons.edit,
                                size: 14,
                                color: AppColors.primary,
                              ),
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

                      // 전체 카테고리 칩 그리드 (프리셋/커스텀 통합)
                      _buildCategoryGrid(),

                      const SizedBox(height: 16),

                      // 카테고리 추가 폼
                      if (showAddForm) ...[
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  showEmojiPicker = !showEmojiPicker;
                                });
                              },
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
                                child: Builder(
                                  builder: (context) {
                                    tempController ??=
                                        TextEditingController(text: temp);
                                    return CustomTextField(
                                      controller: tempController!,
                                      hintText: '새 카테고리 이름',
                                      onChanged: (v) {
                                        setModalState(() {
                                          temp = v;
                                        });
                                      },
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
                              itemCount: _expenseEmojis.length,
                              itemBuilder: (context, index) {
                                final emoji = _expenseEmojis[index];
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
                            onPressed: temp.trim().isNotEmpty
                                ? () {
                              final name = temp.trim();
                              if (!localCategories.contains(name)) {
                                setModalState(() {
                                  localCategories.add(name);
                                  localEmojis[name] = selectedEmoji;
                                });
                                if (onCategoryAdded != null) {
                                  onCategoryAdded(name, selectedEmoji);
                                }
                                // 입력 초기화 (바텀시트는 그대로 유지)
                                setModalState(() {
                                  temp = '';
                                  tempController?.clear();
                                  selectedEmoji = '💰';
                                });
                              }
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
