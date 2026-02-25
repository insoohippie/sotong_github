// plan_category_sheet.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';
import 'package:sotong_local/component/theme/app_colors.dart';

final List<String> expenseEmojis = [
  // 음식
  '🍕','🍔','🍟','🌭','🥪','🌮','🌯','🥙','🍱','🍜',
  '☕','🥤','🧋','🍵','🍶','🍷','🍸','🍹','🍺','🍻',
  '🎂','🍰','🧁','🍭','🍬','🍫','🍩','🍪','🥧',
  // 취미·생활
  '🎬','🎮','🎯','🎲','🎪','🎨','🎭','🎡','🎠',
  '🛍️','🛒','💍','👕','👖','👗','👠','👟','🎒','👜',
  '🚗','🚕','🚙','🚌','🚎','🏎️','✈️','🚁','🚀','🛸',
  '🚢','⛵','🚤','🛥️','🚂',
  '🏋️','🤸','🧘','🏊','🚴','🏃','⚽','🏀','🏈','🎾',
  '📚','✏️','📝','🎁',
  '🌱','🌿','🌾','🌻','🌺','🌸','🌼','🌷','🌹','🥀',
  '🐕','🐈','🐭','🐹','🐰','🦊','🐻','🐼','🐨','🐯',
  '💊','🏥','⚕️','🩺','💉',
  '📱','💻','⌨️','🖥️','📞','📺','📻',
  '🚓','🚑','🚒','🚐',
  // 돈·부동산·투자
  '💰','💸','💳','🏦','💵','💶','💷','💴','🪙','💎',
  '🏠','🏡','🏢','🏬','🏪','🏫','🏩','🏨','🏛️',
  '📊','📈','📉','💼','🗂️','📁','📋',
  '🖨️','📠',
  '🧬','🦠','🧪','🧫','🧼',
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
  String temp = controller.text;

  // 로컬 복사본
  final List<String> localCategories = [...categories];
  final Map<String, String> localEmojis = Map<String, String>.from(categoryEmojis);

  // 입력 컨트롤러
  final tempController = TextEditingController(text: '');

  // UI 상태
  String selectedEmoji = '💰';
  bool showEmojiPicker = false;

  // 인라인 에러
  String? inlineError;
  Timer? inlineErrorTimer;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      // ✅ 바텀시트 닫힌 뒤 Timer가 setState 못하게 안전장치
      void safeSetModalState(void Function(void Function()) setModalState, void Function() fn) {
        if (!ctx.mounted) return;
        setModalState(fn);
      }

      void showInlineError(StateSetter setModalState, String msg) {
        inlineErrorTimer?.cancel();
        safeSetModalState(setModalState, () => inlineError = msg);

        inlineErrorTimer = Timer(const Duration(seconds: 2), () {
          if (!ctx.mounted) return; // ✅ 핵심(크래시 방지)
          setModalState(() => inlineError = null);
        });
      }

      void clearInlineError(StateSetter setModalState) {
        inlineErrorTimer?.cancel();
        safeSetModalState(setModalState, () => inlineError = null);
      }

      Future<void> pickAndClose({
        required String name,
        required String emoji,
      }) async {
        // ✅ 키보드/포커스 해제
        FocusScope.of(ctx).unfocus();

        // ✅ 타이머 정리(닫힌 뒤 setState 방지)
        inlineErrorTimer?.cancel();

        // 선택 반영
        controller.text = name;
        onSelected(name);
        onSelectedWithEmoji?.call(name, emoji);

        // 키보드가 내려갈 틈을 아주 조금 주고 닫기(UX)
        await Future.delayed(const Duration(milliseconds: 80));
        if (ctx.mounted) Navigator.pop(ctx);
      }

      bool isDuplicateSelected(String picked) {
        final current = (currentSelectedName ?? '').trim();
        return alreadySelectedNames.contains(picked) && picked != current;
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          Widget buildChipContent(String name, bool selected) {
            final emoji = (localEmojis[name]?.trim().isNotEmpty ?? false)
                ? localEmojis[name]!.trim()
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
                final double chipWidth = (constraints.maxWidth - spacing * 3) / 4;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: localCategories.map((name) {
                    final picked = name.trim();
                    final bool selected = temp == picked;
                    final bool disabled = isDuplicateSelected(picked);

                    return SizedBox(
                      width: chipWidth,
                      child: GestureDetector(
                        onTap: () async {
                          if (disabled) {
                            showInlineError(setModalState, '이미 선택된 카테고리입니다.');
                            return;
                          }

                          final emoji = (localEmojis[picked]?.trim().isNotEmpty ?? false)
                              ? localEmojis[picked]!.trim()
                              : '💰';

                          setModalState(() => temp = picked);
                          clearInlineError(setModalState);

                          await pickAndClose(name: picked, emoji: emoji);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: buildChipContent(picked, selected),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          }

          Future<void> handleAdd() async {
            final name = tempController.text.trim();
            if (name.isEmpty) return;

            if (localCategories.contains(name)) {
              showInlineError(setModalState, '이미 있는 카테고리 이름이에요.');
              return;
            }

            if (isDuplicateSelected(name)) {
              showInlineError(setModalState, '이미 선택된 카테고리입니다.');
              return;
            }

            final emoji = selectedEmoji.trim().isNotEmpty ? selectedEmoji.trim() : '💰';

            // ✅ 추가 + VM 저장
            setModalState(() {
              localCategories.add(name);
              localEmojis[name] = emoji;
              temp = name;
              showEmojiPicker = false;
            });

            onCategoryAdded?.call(name, emoji);
            clearInlineError(setModalState);

            // ✅ 추가하자마자 선택 + 닫기
            await pickAndClose(name: name, emoji: emoji);
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
                      const Text(
                        '카테고리 선택',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),

                      // ✅ 인라인 에러 (항상 같은 자리에서 보여서 안 가려짐)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 150),
                        child: inlineError == null
                            ? const SizedBox(height: 0)
                            : Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
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

                      const SizedBox(height: 16),

                      // ✅ 항상 보이는 입력/이모지/추가 버튼
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
                                controller: tempController,
                                hintText: '새 카테고리 이름',
                                onChanged: (_) {
                                  // 입력 중 에러 지우고 싶으면 활성화
                                  // clearInlineError(setModalState);
                                },
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
                          onPressed: handleAdd,
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