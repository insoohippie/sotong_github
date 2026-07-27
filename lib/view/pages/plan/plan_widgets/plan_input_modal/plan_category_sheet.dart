// plan_category_sheet.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sotong/component/inputs/custom_text_field.dart';
import 'package:sotong/component/theme/app_colors.dart';

final List<String> expenseEmojis = [
  // 음식
  '🍕', '🍔', '🍟', '🌭', '🥪', '🌮', '🌯', '🥙', '🍱', '🍜',
  '☕', '🥤', '🧋', '🍵', '🍶', '🍷', '🍸', '🍹', '🍺', '🍻',
  '🎂', '🍰', '🧁', '🍭', '🍬', '🍫', '🍩', '🍪', '🥧',
  // 취미·생활
  '🎬', '🎮', '🎯', '🎲', '🎪', '🎨', '🎭', '🎡', '🎠',
  '🛍️', '🛒', '💍', '👕', '👖', '👗', '👠', '👟', '🎒', '👜',
  '🚗', '🚕', '🚙', '🚌', '🚎', '🏎️', '✈️', '🚁', '🚀', '🛸',
  '🚢', '⛵', '🚤', '🛥️', '🚂',
  '🏋️', '🤸', '🧘', '🏊', '🚴', '🏃', '⚽', '🏀', '🏈', '🎾',
  '📚', '✏️', '📝', '🎁',
  '🌱', '🌿', '🌾', '🌻', '🌺', '🌸', '🌼', '🌷', '🌹', '🥀',
  '🐕', '🐈', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯',
  '💊', '🏥', '⚕️', '🩺', '💉',
  '📱', '💻', '⌨️', '🖥️', '📞', '📺', '📻',
  '🚓', '🚑', '🚒', '🚐',
  // 돈·부동산·투자
  '💰', '💸', '💳', '🏦', '💵', '💶', '💷', '💴', '🪙', '💎',
  '🏠', '🏡', '🏢', '🏬', '🏪', '🏫', '🏩', '🏨', '🏛️',
  '📊', '📈', '📉', '💼', '🗂️', '📁', '📋',
  '🖨️', '📠',
  '🧬', '🦠', '🧪', '🧫', '🧼',
];

Future<void> openPlanCategorySheet(
  BuildContext context,
  TextEditingController controller,
  void Function(String) onSelected, {
  required List<String> categories,
  required Map<String, String> categoryEmojis,

  /// ✅ 다른 행에서 이미 선택된 카테고리들
  required Set<String> alreadySelectedNames,
  String? currentSelectedName,

  void Function(String name, String emoji)? onSelectedWithEmoji,

  /// ✅ (name, emoji) 저장 + key 보장은 VM에서 처리
  void Function(String name, String emoji)? onCategoryAdded,

  /// (호환용) 여기선 안씀
  void Function(String name)? onCategoryRemoved,
  void Function(List<String> newOrder)? onReorder,
}) async {
  String temp = controller.text.trim();

  // 로컬 복사본 (시트 내부 UI는 이걸로만 동작)
  final List<String> localCategories = [...categories];
  final Map<String, String> localEmojis = Map<String, String>.from(
    categoryEmojis,
  );

  // 입력 컨트롤러
  final tempController = TextEditingController(text: '');

  // UI 상태
  String selectedEmoji = '💰';
  bool showEmojiPicker = false;
  bool showAddUI = false;

  // 인라인 에러
  String? inlineError;
  Timer? inlineErrorTimer;

  // 닫힘 안전장치
  bool closing = false;
  bool routeListenerAttached = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (modalContext, setModalState) {
          final theme = Theme.of(modalContext);
          final isDark = theme.brightness == Brightness.dark;
          final panelBg = isDark
              ? theme.colorScheme.surface
              : const Color(0xFFF9FAFB);
          final chipBg = isDark
              ? theme.colorScheme.surfaceContainerHighest
              : const Color(0xFFF3F4F6);
          final chipBorder = isDark
              ? theme.dividerColor
              : const Color(0xFFE5E7EB);
          final titleColor = theme.colorScheme.onSurface;
          final subTextColor = theme.colorScheme.onSurfaceVariant;

          // ✅ 드래그 닫기/백버튼 포함: reverse/dismissed 순간부터 setState 금지
          if (!routeListenerAttached) {
            routeListenerAttached = true;
            final route = ModalRoute.of(modalContext);
            route?.animation?.addStatusListener((status) {
              if (status == AnimationStatus.reverse ||
                  status == AnimationStatus.dismissed) {
                closing = true;
                inlineErrorTimer?.cancel();
              }
            });
          }

          void safeSet(void Function() fn) {
            if (closing) return;
            if (!modalContext.mounted) return;
            setModalState(fn);
          }

          void showInlineError(String msg) {
            inlineErrorTimer?.cancel();
            safeSet(() => inlineError = msg);

            inlineErrorTimer = Timer(const Duration(seconds: 2), () {
              if (closing) return;
              if (!modalContext.mounted) return;
              setModalState(() => inlineError = null);
            });
          }

          void clearInlineError() {
            inlineErrorTimer?.cancel();
            safeSet(() => inlineError = null);
          }

          bool isDuplicateSelected(String picked) {
            final current = (currentSelectedName ?? '').trim();
            return alreadySelectedNames.contains(picked) && picked != current;
          }

          Widget chipBodyPlanStyle({
            required String name,
            required String emoji,
            required bool selected,
            double height = 60,
          }) {
            return Container(
              width: double.infinity,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : chipBg,
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
                        color: selected ? Colors.white : titleColor,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          /// ✅ 선택 + 닫기 (키보드/추가UI 먼저 정리 -> pop)
          Future<void> pickAndClose({
            required String name,
            required String emoji,
          }) async {
            if (closing) return;
            closing = true;
            inlineErrorTimer?.cancel();

            // ✅ 추가 UI 열려있으면 먼저 닫고 초기화 (키보드/레이아웃 변화 최소화)
            if (showAddUI || showEmojiPicker) {
              try {
                setModalState(() {
                  showAddUI = false;
                  showEmojiPicker = false;
                  selectedEmoji = '💰';
                  tempController.clear();
                  inlineError = null;
                });
              } catch (_) {}
            }

            FocusScope.of(modalContext).unfocus();
            // ✅ 키보드 내려갈 시간
            await Future.delayed(const Duration(milliseconds: 120));

            controller.text = name;
            onSelected(name);
            onSelectedWithEmoji?.call(name, emoji);

            if (modalContext.mounted) Navigator.pop(modalContext);
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
                  children: localCategories.map((name) {
                    final picked = name.trim();
                    final bool selected = temp == picked;
                    final bool disabled = isDuplicateSelected(picked);

                    final emoji =
                        (localEmojis[picked]?.trim().isNotEmpty ?? false)
                        ? localEmojis[picked]!.trim()
                        : '💰';

                    return SizedBox(
                      width: chipWidth,
                      height: 60,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (disabled) {
                            showInlineError('이미 선택된 카테고리입니다.');
                            return;
                          }
                          setModalState(() => temp = picked);
                          clearInlineError();
                          await pickAndClose(name: picked, emoji: emoji);
                        },
                        child: Opacity(
                          opacity: disabled ? 0.35 : 1.0,
                          child: chipBodyPlanStyle(
                            name: picked,
                            emoji: emoji,
                            selected: selected,
                            height: 60,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }

          /// ✅ 해결 B: "추가 -> 닫기(선택) -> 닫힌 다음 VM 저장"
          Future<void> handleAdd() async {
            final name = tempController.text.trim();
            if (name.isEmpty) return;

            if (localCategories.contains(name)) {
              showInlineError('이미 있는 카테고리 이름이에요.');
              return;
            }

            if (isDuplicateSelected(name)) {
              showInlineError('이미 선택된 카테고리입니다.');
              return;
            }

            final emoji = selectedEmoji.trim().isNotEmpty
                ? selectedEmoji.trim()
                : '💰';

            // ✅ 시트 내부 리스트 먼저 반영
            setModalState(() {
              localCategories.add(name);
              localEmojis[name] = emoji;
              temp = name;
              showEmojiPicker = false;
            });

            clearInlineError();

            // ✅ 1) 먼저 선택+닫기(pop)
            await pickAndClose(name: name, emoji: emoji);

            // ✅ 2) pop 이후(다음 이벤트루프)에 VM 저장/notify
            scheduleMicrotask(() {
              onCategoryAdded?.call(name, emoji);
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(modalContext).viewInsets.bottom,
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

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ 타이틀 + 플러스 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '카테고리 선택',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (closing) return;
                              setModalState(() {
                                showAddUI = !showAddUI;
                                if (!showAddUI) {
                                  showEmojiPicker = false;
                                  selectedEmoji = '💰';
                                  tempController.clear();
                                }
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: showAddUI
                                    ? (isDark
                                          ? theme.colorScheme.surface
                                          : const Color(0xFFD1D5DB))
                                    : chipBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: showAddUI
                                      ? (isDark
                                            ? theme.dividerColor
                                            : const Color(0xFF9CA3AF))
                                      : chipBorder,
                                ),
                              ),
                              child: Icon(
                                showAddUI ? Icons.close : Icons.add,
                                size: 16,
                                color: showAddUI ? titleColor : subTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✅ 인라인 에러
                      AnimatedSize(
                        duration: const Duration(milliseconds: 150),
                        child: inlineError == null
                            ? const SizedBox(height: 0)
                            : Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Text(
                                    inlineError!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),
                      buildCategoryGrid(),

                      // ✅ 추가 UI (플러스 버튼 눌렀을 때만)
                      if (showAddUI) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (closing) return;
                                setModalState(
                                  () => showEmojiPicker = !showEmojiPicker,
                                );
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: chipBg,
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
                                  controller: tempController,
                                  hintText: '새 카테고리 이름',
                                  onChanged: (_) {},
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
                              color: panelBg,
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
                              itemCount: expenseEmojis.length,
                              itemBuilder: (context, index) {
                                final emoji = expenseEmojis[index];
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (closing) return;
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
                            onPressed: closing ? null : handleAdd,
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

  // ✅ 닫힌 뒤 정리
  closing = true;
  inlineErrorTimer?.cancel();
  tempController.dispose();
}
