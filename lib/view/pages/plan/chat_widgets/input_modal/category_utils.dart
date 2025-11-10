import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

/// 카테고리 프리셋
class CatPreset {
  final String name;
  final IconData icon;
  const CatPreset(this.name, this.icon);
}

/// ✅ 프리셋 세트 3종
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

// 프리셋 카테고리별 기본 이모지 반환 함수
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

/// 카테고리 Pill (왼쪽 칩)
class CategoryPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final VoidCallback onClear;
  final double height;
  final List<CatPreset> presets;
  final String? customEmoji; // 사용자 추가 카테고리의 이모지

  /// ✅ 예산 초과 + 해당 행에 입력이 있을 때 붉은 배경 강조
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

    // ✅ 배경색: 입력 있고 highlight면 붉은색, 아니면 기존 색
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
            // 프리셋 카테고리면 아이콘, 사용자 카테고리면 이모지, 빈 상태면 + 아이콘
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

/// ✅ 카테고리 선택 바텀시트 (프리셋 주입받음)
Future<void> openCategorySheet(
  BuildContext context,
  TextEditingController controller,
  void Function(String) onSelected, {
  required List<CatPreset> presets,
  List<bool>? enabledStates,
  VoidCallback? onCategorySettingsTap,
  List<String>? customCategories,
  Function(String)? onCustomCategoryAdded,
  Function(String)? onCustomCategoryRemoved,
  Function(String, String)?
  onCustomCategoryAddedWithEmoji, // 카테고리와 이모지를 함께 전달하는 콜백
  Map<String, String>? categoryEmojis, // 카테고리별 이모지 정보
}) async {
  String temp = controller.text;
  TextEditingController? tempController;
  List<String> localCustomCategories = customCategories ?? []; // 전달받은 카테고리 사용
  bool isEditMode = false; // 편집 모드 상태
  String selectedEmoji = '💰'; // 선택된 이모지
  bool showEmojiPicker = false; // 이모지 선택기 표시 여부
  bool showAddForm = false; // 카테고리 추가 폼 표시 여부
  Map<String, String> localCategoryEmojis =
      categoryEmojis ?? {}; // 전달받은 이모지 정보 사용

  // 소비 관련 이모지 리스트
  final List<String> expenseEmojis = [
    '💰',
    '💸',
    '💳',
    '🏦',
    '💵',
    '💶',
    '💷',
    '💴',
    '🪙',
    '💎',
    '🍕',
    '🍔',
    '🍟',
    '🌭',
    '🥪',
    '🌮',
    '🌯',
    '🥙',
    '🍱',
    '🍜',
    '☕',
    '🥤',
    '🧋',
    '🍵',
    '🍶',
    '🍷',
    '🍸',
    '🍹',
    '🍺',
    '🍻',
    '🛍️',
    '🛒',
    '💍',
    '👕',
    '👖',
    '👗',
    '👠',
    '👟',
    '🎒',
    '👜',
    '🎬',
    '🎮',
    '🎯',
    '🎲',
    '🎪',
    '🎨',
    '🎭',
    '🎪',
    '🎡',
    '🎠',
    '🚗',
    '🚕',
    '🚙',
    '🚌',
    '🚎',
    '🏎️',
    '🚓',
    '🚑',
    '🚒',
    '🚐',
    '✈️',
    '🚁',
    '🚀',
    '🛸',
    '🚢',
    '⛵',
    '🚤',
    '🛥️',
    '🚁',
    '🚂',
    '🏠',
    '🏡',
    '🏢',
    '🏬',
    '🏪',
    '🏫',
    '🏩',
    '🏨',
    '🏦',
    '🏛️',
    '💊',
    '🏥',
    '⚕️',
    '🩺',
    '💉',
    '🧬',
    '🦠',
    '🧪',
    '🧫',
    '🧼',
    '📱',
    '💻',
    '⌨️',
    '🖥️',
    '🖨️',
    '📠',
    '📞',
    '☎️',
    '📺',
    '📻',
    '🏋️',
    '🤸',
    '🧘',
    '🏊',
    '🚴',
    '🏃',
    '⚽',
    '🏀',
    '🏈',
    '🎾',
    '📚',
    '✏️',
    '📝',
    '📋',
    '📊',
    '📈',
    '📉',
    '💼',
    '🗂️',
    '📁',
    '🎁',
    '🎂',
    '🍰',
    '🧁',
    '🍭',
    '🍬',
    '🍫',
    '🍩',
    '🍪',
    '🥧',
    '🌱',
    '🌿',
    '🌾',
    '🌻',
    '🌺',
    '🌸',
    '🌼',
    '🌷',
    '🌹',
    '🥀',
    '🐕',
    '🐈',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
  ];

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
          return Padding(
            padding: const EdgeInsets.all(16),
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

                // 전체 내용을 동일한 너비로 맞추기 위한 컨테이너
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더 (제목 + 추가 버튼)
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
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                showAddForm = !showAddForm;
                                if (showAddForm) {
                                  // 폼을 열 때 입력창 초기화
                                  tempController?.clear();
                                  temp = '';
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
                      const SizedBox(height: 12),
                      // 카테고리 프리셋들 (활성화된 것만 표시)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: presets
                            .asMap()
                            .entries
                            .where((entry) {
                              // enabledStates가 제공되지 않으면 모든 카테고리 표시
                              if (enabledStates == null) return true;
                              // enabledStates가 제공되면 해당 인덱스의 상태 확인
                              return entry.key < enabledStates.length &&
                                  enabledStates[entry.key];
                            })
                            .map((entry) {
                              final p = entry.value;
                              final selected = temp == p.name;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 프리셋 카테고리별 기본 이모지 추가
                                    Text(
                                      _getPresetEmoji(p.name),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(p.name),
                                  ],
                                ),
                                selected: selected,
                                onSelected: (_) {
                                  setModalState(() {
                                    temp = p.name;
                                    tempController?.text = temp;
                                  });

                                  // 추가 폼이 열려있지 않으면 바로 모달 닫기
                                  if (!showAddForm) {
                                    controller.text = p.name;
                                    onSelected(p.name);
                                    Navigator.pop(ctx);
                                  }
                                },
                                selectedColor: AppColors.primary,
                                backgroundColor: const Color(0xFFF3F4F6),
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: selected
                                        ? AppColors.primary
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),

                      // 사용자 입력 카테고리들 (두 번째 줄) - 드래그 앤 드롭 가능
                      if (localCustomCategories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        // 편집 모드 안내 텍스트
                        if (isEditMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '편집 모드: 카테고리를 드래그하여 순서를 변경하거나 X로 삭제하세요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: localCustomCategories.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final category = entry.value;
                            final selected = temp == category;

                            return Draggable<String>(
                              data: category,
                              onDragStarted: () {
                                // 드래그 시작 시 편집 모드 활성화
                                setModalState(() {
                                  isEditMode = true;
                                });
                              },
                              onDragEnd: (details) {
                                // 드래그 종료 시 편집 모드 유지 (수동으로 종료)
                              },
                              feedback: Material(
                                color: Colors.transparent,
                                child: Transform.scale(
                                  scale: 1.1,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          localCategoryEmojis[category] ?? '💰',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          category,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      localCategoryEmojis[category] ?? '💰',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: DragTarget<String>(
                                onWillAcceptWithDetails: (details) {
                                  return details.data != category;
                                },
                                onAcceptWithDetails: (details) {
                                  setModalState(() {
                                    final draggedCategory = details.data;
                                    final draggedIndex = localCustomCategories
                                        .indexOf(draggedCategory);
                                    final targetIndex = index;

                                    if (draggedIndex != -1 &&
                                        draggedIndex != targetIndex) {
                                      // 카테고리 순서 변경
                                      localCustomCategories.removeAt(
                                        draggedIndex,
                                      );
                                      localCustomCategories.insert(
                                        draggedIndex < targetIndex
                                            ? targetIndex - 1
                                            : targetIndex,
                                        draggedCategory,
                                      );
                                    }
                                    // 편집 모드 활성화
                                    isEditMode = true;
                                  });
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.primary
                                            : const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (!isEditMode) {
                                              setModalState(() {
                                                temp = category;
                                                tempController?.text = temp;
                                              });

                                              // 추가 폼이 열려있지 않으면 바로 모달 닫기
                                              if (!showAddForm) {
                                                controller.text = category;
                                                onSelected(category);
                                                Navigator.pop(ctx);
                                              }
                                            }
                                          },
                                          onLongPress: () {
                                            setModalState(() {
                                              isEditMode = true;
                                            });
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                localCategoryEmojis[category] ??
                                                    '💰',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                category,
                                                style: TextStyle(
                                                  color: selected
                                                      ? Colors.white
                                                      : const Color(0xFF111827),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // X 버튼 (편집 모드에서만 표시)
                                        if (isEditMode) ...[
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                localCustomCategories.remove(
                                                  category,
                                                );
                                                localCategoryEmojis.remove(
                                                  category,
                                                );
                                                if (onCustomCategoryRemoved !=
                                                    null) {
                                                  onCustomCategoryRemoved(
                                                    category,
                                                  );
                                                }
                                                // 삭제된 카테고리가 선택되어 있다면 선택 해제
                                                if (temp == category) {
                                                  temp = '';
                                                  tempController?.text = '';
                                                }
                                                // 카테고리가 모두 삭제되면 편집 모드 종료
                                                if (localCustomCategories
                                                    .isEmpty) {
                                                  isEditMode = false;
                                                }
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: selected
                                                  ? Colors.white.withOpacity(
                                                      0.8,
                                                    )
                                                  : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),

                        // 편집 모드 종료 버튼
                        if (isEditMode)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      isEditMode = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.grey[700],
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '완료',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                      // 카테고리 추가 폼 (조건부 표시)
                      if (showAddForm) ...[
                        // 이모지 선택기와 카테고리 입력창
                        Row(
                          children: [
                            // 이모지 선택 버튼
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
                            // 카테고리 입력창
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: Builder(
                                  builder: (context) {
                                    tempController ??= TextEditingController(
                                      text: temp,
                                    );
                                    return CustomTextField(
                                      controller: tempController!,
                                      hintText: '다른 카테고리 입력',
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

                        // 이모지 선택기 (표시될 때만)
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

                        const SizedBox(height: 16),

                        // 확인 버튼 (아래로 이동)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: temp.trim().isNotEmpty
                                ? () {
                                    final result = temp.trim();

                                    // 중복되지 않는 경우에만 추가
                                    if (!localCustomCategories.contains(
                                          result,
                                        ) &&
                                        !presets.any(
                                          (preset) => preset.name == result,
                                        )) {
                                      // 카테고리와 이모지를 함께 저장
                                      setModalState(() {
                                        localCustomCategories.add(result);
                                        localCategoryEmojis[result] =
                                            selectedEmoji;
                                      });
                                      // 콜백을 통해 부모에게 새 카테고리 추가 알림
                                      if (onCustomCategoryAdded != null) {
                                        onCustomCategoryAdded(result);
                                      }
                                      // 이모지와 함께 전달하는 콜백
                                      if (onCustomCategoryAddedWithEmoji !=
                                          null) {
                                        onCustomCategoryAddedWithEmoji(
                                          result,
                                          selectedEmoji,
                                        );
                                      }
                                    }

                                    // 결과 설정 및 모달 닫기
                                    controller.text = result;
                                    onSelected(result);
                                    // 추가 폼 닫기
                                    setModalState(() {
                                      showAddForm = false;
                                    });
                                    Navigator.pop(ctx);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '확인',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ], // 카테고리 추가 폼 조건부 표시 종료
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      );
    },
  );
}
