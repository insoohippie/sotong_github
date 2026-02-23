import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/buttons/period_toggle.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

import '../../../../model/category/category_edit_item.dart';
import '../../../../model/category/ref_category_item.dart';

// ✅ 너가 둔 위치에 맞춰 import 경로 조정해줘
// 예) record/record_widgets/drag_grid.dart 라면 그 경로로 바꾸기
import '../../../../view_model/category/spending_category_view_model.dart';
import 'drag_grid.dart';

class RecordCategoryPick {
  final String name;
  final String key;
  final String emoji;
  final String source; // 'plan' | 'ref'

  const RecordCategoryPick({
    required this.name,
    required this.key,
    required this.emoji,
    required this.source,
  });
}

/// ✅ 원하는 순서 그대로 사용
final List<String> recordExpenseEmojis = [
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

Future<RecordCategoryPick?> openRecordCategorySheetWithKey(
    BuildContext context, {
      required List<CategoryEditItem> planItems,
      required List<RefCategoryItem> refItems,
      Future<RefCategoryItem?> Function(String name, String emoji)? onAddRef,
      void Function(String categoryKey)? onRemoveRef,
      void Function(List<String> newOrderKeys)? onReorderRef,
      String? selectedName,
      String? selectedKey,
    }) async {
  // ✅ ref는 모달 안에서만 로컬로 바꾸고, 저장은 콜백으로
  var localRef = List<RefCategoryItem>.from(refItems);

  bool isPlanTab = true;
  bool editMode = false;

  bool showAdd = false;
  bool showEmojiPicker = false;

  String selectedEmoji = '💰';
  final tempNameCtrl = TextEditingController();

  RecordCategoryPick? result;


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
          // -------------------------
          // helpers
          // -------------------------

          void showSheetToast(String message) {
            final overlay = Overlay.of(ctx, rootOverlay: true);
            if (overlay == null) return;

            final entry = OverlayEntry(
              builder: (_) => Positioned(
                left: 16,
                right: 16,
                bottom: 140, // ✅ 시트 위로 살짝 띄우기 (필요하면 120~180 조절)
                child: IgnorePointer(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
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

            overlay.insert(entry);
            Future.delayed(const Duration(milliseconds: 1200), () {
              entry.remove();
            });
          }

          void saveRefOrderIfNeeded() {
            if (!isPlanTab && onReorderRef != null) {
              onReorderRef(localRef.map((e) => e.categoryKey).toList());
            }
          }

          bool _isSameDay(DateTime a, DateTime b) =>
              a.year == b.year && a.month == b.month && a.day == b.day;
          final vm = ctx.watch<SpendingCategoryViewModel>();
          final selectedDate = vm.selectedDate;
          final isToday = _isSameDay(selectedDate, DateTime.now());

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

          bool isSelectedItem({required String key, required String name}) {
            if (selectedKey != null && selectedKey!.isNotEmpty) return selectedKey == key;
            return (selectedName ?? '') == name;
          }

          void onSettingsTap() async {
            if (!isToday) {
              showSheetToast('카테고리 편집은 오늘 날짜에서만 가능해요.');
              return;
            }

            final nav = Navigator.of(ctx, rootNavigator: true);
            await nav.pushNamed('/category_edit');
            if (!ctx.mounted) return;

            final vmRead = ctx.read<SpendingCategoryViewModel>();
            await vmRead.initForDate(vmRead.selectedDate);

            setModalState(() {
              localRef = List<RefCategoryItem>.from(vmRead.refItems);
              editMode = false;
              closeAddUI();
            });
          }

          Widget chipBody({
            required String name,
            required String emoji,
            required bool feedback,
            required bool selected,
            VoidCallback? onDeleteRef,
            double height = 60,
          }) {
            final showDelete = (!isPlanTab && editMode && onDeleteRef != null);

            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: height,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // ✅ 10→8로 살짝 줄임
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: feedback
                        ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4), // ✅ 6→4
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.5,        // ✅ 12→11.5 (60 높이에 안정적으로 들어감)
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : const Color(0xFF111827),
                            height: 1.05,          // ✅ 줄간격 살짝 줄임
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ 삭제 X는 레이아웃에 영향을 안 주도록 우상단 오버레이
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
            );
          }

          // -------------------------
          // Plan chip
          // -------------------------
          Widget planChip(CategoryEditItem item) {
            final selected = isSelectedItem(key: item.categoryKey, name: item.name);
            final w = (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4;

            return SizedBox(
              width: w,
              child: GestureDetector(
                onTap: () {
                  if (editMode) return;
                  result = RecordCategoryPick(
                    name: item.name,
                    key: item.categoryKey,
                    emoji: item.emoji,
                    source: 'plan',
                  );
                  Navigator.pop(ctx);
                },
                child: chipBody(
                  name: item.name,
                  emoji: item.emoji,
                  feedback: false,
                  selected: selected,
                  height: 60,
                ),
              ),
            );
          }

          // -------------------------
          // ref grid itemBuilder
          // -------------------------
          Widget refGridItem(RefCategoryItem item, int index) {
            final selected = isSelectedItem(key: item.categoryKey, name: item.name);

            return GestureDetector(
              onTap: () {
                if (editMode) return;
                result = RecordCategoryPick(
                  name: item.name,
                  key: item.categoryKey,
                  emoji: item.emoji,
                  source: 'ref',
                );
                Navigator.pop(ctx);
              },
              onLongPress: () {
                if (isPlanTab) return;
                setModalState(() {
                  enterEditMode();
                });
              },
              child: chipBody(
                name: item.name,
                emoji: item.emoji,
                feedback: false,
                selected: selected,
                height: 60,
                onDeleteRef: editMode
                    ? () {
                  setModalState(() {
                    localRef.removeWhere((e) => e.categoryKey == item.categoryKey);
                    if (localRef.isEmpty) editMode = false;
                  });
                  onRemoveRef?.call(item.categoryKey);
                  // 삭제 후에도 순서 저장(선택사항이지만 UX 좋음)
                  onReorderRef?.call(localRef.map((e) => e.categoryKey).toList());
                }
                    : null,
              ),
            );
          }

          // -------------------------
          // toggle add
          // -------------------------
          void toggleAdd() {
            if (isPlanTab) {
              showSheetToast('플랜 카테고리는 오늘 날짜에서만 수정이 가능해요.');
              return;
            }

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

          final planChips = planItems.map(planChip).toList();

          // -------------------------
          // UI
          // -------------------------
          final bool settingsEnabled = isToday;
          return WillPopScope(
            onWillPop: () async {
              saveRefOrderIfNeeded();
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
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TwoOptionToggle(
                        labels: const ['플랜', '참고'],
                        selected: isPlanTab ? '플랜' : '참고',
                        onChanged: (v) {
                          final nextIsPlan = (v == '플랜');

                          setModalState(() {
                            // ✅ ref -> plan으로 나갈 때 저장 + 편집 종료 + 추가칸 닫기
                            if (isPlanTab == false && nextIsPlan == true) {
                              saveRefOrderIfNeeded();
                              editMode = false;
                              closeAddUI();
                            }
                            isPlanTab = nextIsPlan;

                            // ✅ plan 탭에서는 편집/추가 상태 의미 없으니 정리
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
                              onTap: () {
                                setModalState(() {
                                  saveRefOrderIfNeeded();
                                  closeAddUI();
                                  editMode = false;
                                });
                              },
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
                            onTap: toggleAdd,
                            child: Opacity(
                              opacity: isPlanTab ? 0.35 : 1,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: showAdd ? Color(0xFFD1D5DB) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: showAdd ? Color(0xFF9CA3AF) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Icon(
                                  showAdd ? Icons.close : Icons.add,
                                  size: 16,
                                  color: showAdd ? Color(0xFF374151) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Opacity(
                            opacity: settingsEnabled ? 1 : 0.35,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: settingsEnabled
                                  ? onSettingsTap
                                  : () => showSheetToast('카테고리 편집은 오늘 날짜에서만 가능해요.'),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ✅ plan: Wrap / ref: DragGrid
                  if (isPlanTab)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: planChips,
                    )
                  else
                    DragGrid<RefCategoryItem>(
                      itemList: localRef,
                      itemKey: (item) => ValueKey(item.categoryKey), // ✅ 핵심
                      reorderableKey: ValueKey(
                        'ref_${localRef.map((e) => e.categoryKey).join(',')}',
                      ),
                      sliverGridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: 60,
                      ),
                      enableLongPress: editMode,
                      onReorder: (newList) {
                        setModalState(() {
                          localRef = List<RefCategoryItem>.from(newList);
                        });
                        onReorderRef?.call(localRef.map((e) => e.categoryKey).toList());
                      },
                      itemBuilder: (context, item, index) => refGridItem(item, index),
                    ),

                  const SizedBox(height: 16),

                  // ✅ add UI (ref 탭에서만)
                  if (!isPlanTab && showAdd) ...[
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
                          itemCount: recordExpenseEmojis.length,
                          itemBuilder: (context, index) {
                            final emoji = recordExpenseEmojis[index];
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
                            : () async {
                          final name = tempNameCtrl.text.trim();
                          final dupInPlan = planItems.any((e) => e.name == name);
                          final dupInRef = localRef.any((e) => e.name == name);
                          if (dupInPlan || dupInRef) return;

                          final created = await onAddRef?.call(name, selectedEmoji);
                          if (created == null) return;

                          setModalState(() {
                            localRef.add(created);
                          });

                          // ✅ 요구사항: 추가 완료되면 “추가 영역 닫기”
                          setModalState(() {
                            closeAddUI();
                            // 추가 후 편집모드로 유지할지 여부는 선택
                            // editMode = false;
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

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  tempNameCtrl.dispose();
  return result;
}
