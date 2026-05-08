import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/buttons/period_toggle.dart';
import 'package:sotong_local/component/inputs/custom_text_field.dart';

import '../../../../../model/category/category_edit_item.dart';
import '../../../../../model/category/ref_category_item.dart';

import '../../../../../view_model/category/spending_category_view_model.dart';
import '../drag_grid.dart';

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
      Future<void> Function(String categoryKey)? onRemoveRef,
      Future<void> Function(List<String> newOrderKeys)? onReorderRef,
      String? selectedName,
      String? selectedKey,
    }) async {
  // ✅ ref: "저장된 상태" 기준 스냅샷(편집 완료 눌러야만 커밋)
  var committedRef = List<RefCategoryItem>.from(refItems);

  // ✅ ref: 모달 내부에서만 변경되는 draft
  var localRef = List<RefCategoryItem>.from(committedRef);

  // ✅ ref 삭제도 편집 완료 때만 저장되도록 큐에 담기
  final pendingRemoveKeys = <String>{};

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
          final vm = ctx.watch<SpendingCategoryViewModel>();
          final planItemsLive = vm.planItems;

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
                bottom: 140,
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

          bool _isSameDay(DateTime a, DateTime b) =>
              a.year == b.year && a.month == b.month && a.day == b.day;

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

          void cancelEditChanges() {
            // ✅ 편집 완료 없이 닫거나 탭 전환 시: 변경사항 폐기
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
              await onReorderRef!(localRef.map((e) => e.categoryKey).toList());
            }

            committedRef = List<RefCategoryItem>.from(localRef);
          }

          bool _hasUnsavedEditChanges() {
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

          Future<bool> _confirmDiscardDialog() async {
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
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                );
              },
            );
            return res ?? false;
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

            // ✅ 여기만 제대로 하면 plan/ref 모두 최신값으로 즉시 반영됨
            final vmRead = ctx.read<SpendingCategoryViewModel>();
            await vmRead.initForDate(vmRead.selectedDate);

            setModalState(() {
              // ✅ ref만: 시트 편집 로직 때문에 committed/local 갱신 필요
              committedRef = List<RefCategoryItem>.from(vmRead.refItems);
              localRef = List<RefCategoryItem>.from(committedRef);
              pendingRemoveKeys.clear();
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            color: selected ? Colors.white : const Color(0xFF111827),
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
            );
          }

          // -------------------------
          // Plan chip (live planItems)
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
              // ✅ 꾹 눌러서 편집 진입(참고 탭에서만)
              onLongPress: () {
                if (isPlanTab) return;
                setModalState(() => enterEditMode());
              },
              child: chipBody(
                name: item.name,
                emoji: item.emoji,
                feedback: false,
                selected: selected,
                height: 60,
                onDeleteRef: editMode
                    ? () {
                  // ✅ 삭제도 "편집 완료" 눌러야 저장되도록 로컬 반영 + 큐 적재
                  setModalState(() {
                    pendingRemoveKeys.add(item.categoryKey);
                    localRef.removeWhere((e) => e.categoryKey == item.categoryKey);
                  });
                }
                    : null,
              ),
            );
          }

          // -------------------------
          // add (ref에서만)
          // -------------------------
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

          final planChips = planItemsLive.map(planChip).toList();
          final bool settingsEnabled = isToday;

          // ✅ ref grid: 편집 모드 아닐 때는 드래그 기능 자체 없음(절대 안움직임)
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
                reorderableKey: const ValueKey('ref_grid_edit'),
                sliverGridDelegate: gridDelegate,
                enableLongPress: true,
                longPressDelay: Duration.zero, // ✅ 바로 드래그 시작(최대한 즉시)
                onReorder: (newList) {
                  // ✅ 저장 호출 X (편집 완료에서만)
                  setModalState(() {
                    localRef = List<RefCategoryItem>.from(newList);
                  });
                },
                itemBuilder: (context, item, index) => refGridItem(item, index),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: gridDelegate,
                itemCount: localRef.length,
                itemBuilder: (context, index) => refGridItem(localRef[index], index),
              ),
            );
          }

          return WillPopScope(
            onWillPop: () async {
              // ✅ 편집 중이고 변경사항 있으면: 폐기 확인
              if (_hasUnsavedEditChanges()) {
                final discard = await _confirmDiscardDialog();
                if (!discard) return false;

                setModalState(() => cancelEditChanges());
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
                        onChanged: (v) async {
                          final nextIsPlan = (v == '플랜');

                          // ✅ ref 편집 중 + 변경사항 있으면 탭 전환 전에 폐기 확인
                          if (!isPlanTab && editMode && _hasUnsavedEditChanges()) {
                            final discard = await _confirmDiscardDialog();
                            if (!discard) return;
                            setModalState(() => cancelEditChanges());
                          }

                          setModalState(() {
                            isPlanTab = nextIsPlan;

                            // ✅ plan 탭에서는 add/edit 의미 없으니 정리
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
                          // ✅ 편집 완료는 ref + editMode에서만
                          if (!isPlanTab && editMode)
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

                          // ✅ 추가 버튼: 참고 탭에서만 보이게(플랜 탭에서는 숨김)
                          if (!isPlanTab) ...[
                            GestureDetector(
                              onTap: toggleAdd,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: showAdd ? const Color(0xFFD1D5DB) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: showAdd ? const Color(0xFF9CA3AF) : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Icon(
                                  showAdd ? Icons.close : Icons.add,
                                  size: 16,
                                  color: showAdd ? const Color(0xFF374151) : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // ✅ 설정 버튼: 기존대로 오늘 아니면 비활성 + 토스트
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
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
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

                  IndexedStack(
                    index: isPlanTab ? 0 : 1,
                    children: [

                      // plan
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: planChips,
                      ),

                      // ref
                      buildRefGrid(),
                    ],
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

                          // ✅ 중복 체크: plan은 live, ref는 localRef 기준
                          final dupInPlan = planItemsLive.any((e) => e.name == name);
                          final dupInRef = localRef.any((e) => e.name == name);
                          if (dupInPlan || dupInRef) return;

                          final created = await onAddRef?.call(name, selectedEmoji);
                          if (created == null) return;

                          setModalState(() {
                            // ✅ 추가는 onAddRef가 저장까지 끝내므로 즉시 반영 + 커밋으로 취급
                            localRef.add(created);
                            committedRef = List<RefCategoryItem>.from(localRef);
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