import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/theme/app_colors.dart';

// ✅ 너 프로젝트에 이미 있는 텍스트/버튼 스타일 쓰면 import 연결해서 교체 가능
// import '../../../component/theme/app_text_styles.dart';
// import '../../../component/buttons/small_rounded_button.dart';

import '../../../model/category/category_edit_row.dart';
import '../../../model/category/ref_category_item.dart';
import '../../../model/category/category_edit_item.dart';
import '../../../view_model/category/category_edit_view_model.dart';

// ✅ 모달 2개는 그대로 유지
import 'category_widgets/category_edit_tiles.dart';
import 'category_widgets/category_name_modal.dart';
import 'category_widgets/category_amount_modal.dart';

// ✅ 이건 네 기존 경로에 맞게 수정 필요!
// 예전 CategoryListsSection에서 쓰던 그 import 경로를 여기로 옮겨오면 됨.
import 'category_widgets/category_plan_progress_box.dart';

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage>
    with TickerProviderStateMixin {
  bool _showNameSheet = false;
  bool _showAmountSheet = false;

  late final AnimationController _nameSheetCtrl;
  late final Animation<Offset> _nameSheetSlide;
  late final Animation<double> _nameScrimFade;

  late final AnimationController _amountSheetCtrl;
  late final Animation<Offset> _amountSheetSlide;
  late final Animation<double> _amountScrimFade;

  String? _editingCategoryId;
  String? _editingCategoryName;
  String? _editingCategoryEmoji;
  bool _editingIsPlan = false;
  int _editingAmount = 1;

  RefCategoryItem? _pendingMoveRefItem;
  int? _pendingMoveTargetIndex;

  @override
  void initState() {
    super.initState();

    _nameSheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _nameSheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _nameSheetCtrl,
        curve: Curves.easeOut,
      ),
    );
    _nameScrimFade = CurvedAnimation(
      parent: _nameSheetCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _amountSheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _amountSheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _amountSheetCtrl,
        curve: Curves.easeOut,
      ),
    );
    _amountScrimFade = CurvedAnimation(
      parent: _amountSheetCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    // ✅ CategoryEditViewModel은 main.dart에서 전역 Provider로 살아있기 때문에
    // initOnce()를 쓰면 이전 draft가 남을 수 있음.
    // 페이지에 들어올 때마다 오늘 기준으로 최신 플랜/RefData를 다시 로드한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryEditViewModel>().refreshForToday();
    });
  }

  @override
  void dispose() {
    _nameSheetCtrl.dispose();
    _amountSheetCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // Helpers (계산/포맷/리오더)
  // =========================================================
  int _calcDailySum(List<CategoryEditItem> planList) {
    return planList.fold<int>(0, (sum, c) => sum + (c.dailyAmount ?? 0));
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    )}원';
  }

  List<String> _reorderKeys({
    required List<String> keys,
    required int oldIndex,
    required int newIndex,
  }) {
    final list = List<String>.from(keys);
    if (oldIndex < 0 || oldIndex >= list.length) return list;
    if (newIndex < 0 || newIndex > list.length) return list;

    if (oldIndex < newIndex) newIndex -= 1;
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    return list;
  }
  List<CategoryEditRow> _buildRows(CategoryEditViewModel vm) {
    return [
      const CategoryEditRow.planHeader(),
      ...vm.draftPlan.map(CategoryEditRow.planItem),
      const CategoryEditRow.planAddButton(),
      const CategoryEditRow.refHeader(),
      ...vm.draftRef.map(CategoryEditRow.refItem),
      const CategoryEditRow.refAddButton(),
    ];
  }

  int _refHeaderIndex(List<CategoryEditRow> rows) {
    return rows.indexWhere((e) => e.type == CategoryEditRowType.refHeader);
  }

  int _countPlanItemsBefore(
      List<CategoryEditRow> rows,
      int insertIndex,
      ) {
    final safeIndex = insertIndex.clamp(0, rows.length);

    return rows
        .take(safeIndex)
        .where((e) => e.type == CategoryEditRowType.planItem)
        .length;
  }

  int _countRefItemsBefore(
      List<CategoryEditRow> rows,
      int insertIndex,
      ) {
    final safeIndex = insertIndex.clamp(0, rows.length);

    return rows
        .take(safeIndex)
        .where((e) => e.type == CategoryEditRowType.refItem)
        .length;
  }

  List<String> _planKeysAfterUnifiedInsert({
    required List<CategoryEditRow> withoutMoving,
    required CategoryEditRow moving,
    required int insertIndex,
  }) {
    final copied = List<CategoryEditRow>.from(withoutMoving);
    final safeIndex = insertIndex.clamp(0, copied.length);

    copied.insert(safeIndex, moving);

    return copied
        .where((e) => e.type == CategoryEditRowType.planItem)
        .map((e) => e.planItem!.categoryKey)
        .toList(growable: false);
  }

  List<String> _refKeysAfterUnifiedInsert({
    required List<CategoryEditRow> withoutMoving,
    required CategoryEditRow moving,
    required int insertIndex,
  }) {
    final copied = List<CategoryEditRow>.from(withoutMoving);
    final safeIndex = insertIndex.clamp(0, copied.length);

    copied.insert(safeIndex, moving);

    return copied
        .where((e) => e.type == CategoryEditRowType.refItem)
        .map((e) => e.refItem!.categoryKey)
        .toList(growable: false);
  }



  Future<void> _handleUnifiedReorder(
      CategoryEditViewModel vm, {
        required List<CategoryEditRow> rows,
        required int oldIndex,
        required int newIndex,
      }) async {
    if (oldIndex < 0 || oldIndex >= rows.length) return;

    final moving = rows[oldIndex];

    // 헤더/추가 버튼은 이동 금지
    if (moving.isFixed) return;

    var insertIndex = newIndex;

    if (oldIndex < insertIndex) {
      insertIndex -= 1;
    }

    final withoutMoving = List<CategoryEditRow>.from(rows)
      ..removeAt(oldIndex);

    insertIndex = insertIndex.clamp(0, withoutMoving.length);

    final refHeader = _refHeaderIndex(withoutMoving);
    if (refHeader < 0) return;

    final isMovingPlan = moving.type == CategoryEditRowType.planItem;
    final isMovingRef = moving.type == CategoryEditRowType.refItem;

    // 플랜 영역:
    // planHeader 아래 ~ refHeader 위
    // planAddButton 위치에 놓아도 플랜 맨 아래로 인정
    final movingIntoPlan = isMovingRef
        ? insertIndex <= refHeader
        : insertIndex < refHeader;

    // 참고 영역:
    // refHeader 아래 ~ refAddButton 위/아래
    final movingIntoRef = isMovingPlan
        ? insertIndex >= refHeader
        : insertIndex > refHeader;

    // 플랜 내부 정렬
    if (isMovingPlan && movingIntoPlan) {
      final newKeys = _planKeysAfterUnifiedInsert(
        withoutMoving: withoutMoving,
        moving: moving,
        insertIndex: insertIndex,
      );

      vm.draftReorderPlanByKeys(newKeys);
      return;
    }

    // 참고 내부 정렬
    if (isMovingRef && movingIntoRef) {
      final newKeys = _refKeysAfterUnifiedInsert(
        withoutMoving: withoutMoving,
        moving: moving,
        insertIndex: insertIndex,
      );

      vm.draftReorderRefByKeys(newKeys);
      return;
    }

    // 참고 → 플랜 이동
    if (isMovingRef && movingIntoPlan) {
      final item = moving.refItem;
      if (item == null) return;

      final targetPlanIndex = _countPlanItemsBefore(
        withoutMoving,
        insertIndex,
      );

      // ✅ 먼저 화면에서 해당 위치로 이동시킴. 금액은 임시로 -원 표시.
      vm.draftMoveRefToPlanPendingAtIndex(
        refItem: item,
        targetIndex: targetPlanIndex,
      );

      if (mounted) setState(() {});

      // 금액 입력 완료 시 이 categoryKey의 금액만 업데이트할 예정
      _pendingMoveRefItem = item;
      _pendingMoveTargetIndex = null;

      _editingCategoryId = item.categoryKey;
      _editingCategoryName = item.name;
      _editingCategoryEmoji = item.emoji;
      _editingIsPlan = true;
      _editingAmount = 1;

      _showCategoryToast('금액을 입력하면 플랜 카테고리 이동이 완료돼요.');

      await _openAmountSheet();
      return;
    }

    // 플랜 → 참고 이동
    if (isMovingPlan && movingIntoRef) {
      final item = moving.planItem;
      if (item == null) return;

      final targetRefIndex = _countRefItemsBefore(
        withoutMoving,
        insertIndex,
      );

      vm.draftMovePlanToRefAtIndex(
        planItem: item,
        targetIndex: targetRefIndex,
      );

      if (mounted) setState(() {});

      _showCategoryToast('참고 카테고리로 이동했어요. 저장 버튼을 눌러야 반영돼요.');
      return;
    }
  }






  // =========================================================
  // ✅ 뒤로가기 확인 다이얼로그
  // =========================================================
  Future<bool> _confirmLeaveDiscardDraft() async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text(
            '편집 중이에요',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('저장하지 않고 나가면 변경사항이 사라져요.\n그래도 나갈까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('계속 편집'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text(
                '나가기(폐기)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }






  Future<bool> _handleBack(CategoryEditViewModel vm) async {
    if (_showNameSheet) {
      await _closeNameSheet();
      return false;
    }
    if (_showAmountSheet) {
      await _closeAmountSheet();
      return false;
    }

    if (vm.hasUnsavedChanges) {
      final leave = await _confirmLeaveDiscardDraft();
      if (!leave) return false;

      vm.discardDraft();
      _clearEditingState();
      return true;
    }
    return true;
  }

  // =========================================================
  // 저장
  // =========================================================
  Future<void> _save(
      CategoryEditViewModel vm, {
        bool popOnSuccess = true,
      }) async {
    final ok = await vm.saveDraftForSelectedDate();
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리가 저장되었습니다.')),
      );
      if (popOnSuccess) Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.error ?? '저장에 실패했습니다.')),
      );
    }
  }

  Widget _buildBottomSection(CategoryEditViewModel vm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: vm.isSaving ? null : () => _save(vm),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '저장',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // 시트 열기/닫기
  // =========================================================
  Future<void> _closeNameSheet({bool setFalse = true}) async {
    if (!_showNameSheet) return;
    await _nameSheetCtrl.reverse();
    if (!mounted) return;
    if (setFalse) setState(() => _showNameSheet = false);
  }

  Future<void> _closeAmountSheet({bool setFalse = true}) async {
    if (!_showAmountSheet) return;
    await _amountSheetCtrl.reverse();
    if (!mounted) return;
    if (setFalse) setState(() => _showAmountSheet = false);
  }

  Future<void> _openNameSheet() async {
    if (_showAmountSheet) {
      await _closeAmountSheet(setFalse: true);
    }
    if (!mounted) return;

    setState(() => _showNameSheet = true);
    _nameSheetCtrl.forward(from: 0);
  }

  Future<void> _openAmountSheet() async {
    if (_showNameSheet) {
      await _closeNameSheet(setFalse: true);
    }
    if (!mounted) return;

    setState(() => _showAmountSheet = true);
    _amountSheetCtrl.forward(from: 0);
  }

  // =========================================================
  // 이름/이모지 시트 열기
  // =========================================================
  void _openNameForAdd({required bool isPlan}) {
    _editingCategoryId = null;
    _editingCategoryName = null;
    _editingCategoryEmoji = '💰';
    _editingIsPlan = isPlan;
    _editingAmount = 1;

    _pendingMoveRefItem = null;
    _pendingMoveTargetIndex = null;

    _openNameSheet();
  }

  void _openNameForEditPlan(CategoryEditItem item) {
    _editingCategoryId = item.categoryKey;
    _editingCategoryName = item.name;
    _editingCategoryEmoji = item.emoji;
    _editingIsPlan = true;
    _editingAmount = item.dailyAmount ?? 1;

    _pendingMoveRefItem = null;
    _pendingMoveTargetIndex = null;

    _openNameSheet();
  }

  void _openNameForEditRef(RefCategoryItem item) {
    _editingCategoryId = item.categoryKey;
    _editingCategoryName = item.name;
    _editingCategoryEmoji = item.emoji;
    _editingIsPlan = false;
    _editingAmount = 1;

    _pendingMoveRefItem = null;
    _pendingMoveTargetIndex = null;

    _openNameSheet();
  }

  void _onNameComplete(
      CategoryEditViewModel vm, {
        required String name,
        required String emoji,
      }) async {
    final trimmed = name.trim();

    // =========================================================
    // 새 카테고리 추가 모드
    // =========================================================
    if (_editingCategoryId == null) {
      // -----------------------------
      // 플랜 카테고리 추가
      // -----------------------------
      if (_editingIsPlan) {
        final action = vm.resolvePlanCategoryAddAction(
          name: trimmed,
          emoji: emoji,
        );

        switch (action.type) {
          case PlanCategoryAddActionType.blocked:
            _showCategoryToast(action.message ?? '카테고리를 추가할 수 없어요.');
            return;

          case PlanCategoryAddActionType.moveFromRef:
            _showCategoryToast('이미 참고 카테고리로 쓰고 있어요.');
            return;

          case PlanCategoryAddActionType.reuseFromRegistry:
            if (action.categoryKey == null) {
              _showCategoryToast('카테고리를 추가할 수 없어요.');
              return;
            }

            _showCategoryToast(
              action.message ?? '예전에 사용했던 카테고리를 다시 연결했어요.',
            );

            await _closeNameSheet(setFalse: true);
            if (!mounted) return;

            _editingCategoryId = action.categoryKey;
            _editingCategoryName = action.name;
            _editingCategoryEmoji = action.emoji;
            _editingAmount = 1;

            await _openAmountSheet();
            return;

          case PlanCategoryAddActionType.createNew:
            if (action.categoryKey == null) {
              _showCategoryToast('카테고리를 추가할 수 없어요.');
              return;
            }

            await _closeNameSheet(setFalse: true);
            if (!mounted) return;

            _editingCategoryId = action.categoryKey;
            _editingCategoryName = action.name;
            _editingCategoryEmoji = action.emoji;
            _editingAmount = 1;

            await _openAmountSheet();
            return;
        }
      }

      // -----------------------------
      // 참고 카테고리 추가
      // -----------------------------
      final action = vm.resolveRefCategoryAddAction(
        name: trimmed,
        emoji: emoji,
      );

      switch (action.type) {
        case RefCategoryAddActionType.blocked:
          _showCategoryToast(action.message ?? '카테고리를 추가할 수 없어요.');
          return;

        case RefCategoryAddActionType.reuseFromRegistry:
        case RefCategoryAddActionType.createNew:
          await _closeNameSheet(setFalse: true);
          if (!mounted) return;

          final added = vm.draftAddRef(
            name: action.name,
            emoji: action.emoji,
            categoryKey: action.categoryKey,
          );

          if (added == null) {
            final notice = vm.noticeMessage;
            _showCategoryToast(notice ?? '카테고리를 추가하지 못했어요.');
            vm.consumeNoticeMessage();
            return;
          }

          _clearEditingState();
          return;
      }
    }

    // =========================================================
    // 기존 카테고리 수정 모드
    // =========================================================
    if (trimmed.isEmpty) {
      _showCategoryToast('카테고리 이름을 입력해주세요.');
      return;
    }

    await _closeNameSheet(setFalse: true);
    if (!mounted) return;

    if (_editingIsPlan) {
      vm.draftUpdateMeta(
        categoryKey: _editingCategoryId!,
        name: trimmed,
        emoji: emoji,
      );
    } else {
      vm.draftUpdateRefMeta(
        categoryKey: _editingCategoryId!,
        name: trimmed,
        emoji: emoji,
      );
    }

    _clearEditingState();
  }

  void _openAmountForEdit(CategoryEditItem item) {
    _editingCategoryId = item.categoryKey;
    _editingCategoryName = item.name;
    _editingCategoryEmoji = item.emoji;
    _editingIsPlan = true;
    _editingAmount = item.dailyAmount ?? 1;

    _pendingMoveRefItem = null;
    _pendingMoveTargetIndex = null;

    _openAmountSheet();
  }

  void _onAmountComplete(CategoryEditViewModel vm, int amount) async {
    if (amount < 1) return;

    await _closeAmountSheet(setFalse: true);
    if (!mounted) return;

    final id = _editingCategoryId;
    final name = _editingCategoryName;
    final emoji = (_editingCategoryEmoji ?? '💰');

    // ✅ 참고 카테고리 → 플랜 카테고리 이동 케이스
    if (_pendingMoveRefItem != null) {
      final movingRefItem = _pendingMoveRefItem!;

      // ✅ 이미 플랜 목록으로 이동된 상태이므로 금액만 업데이트
      vm.draftUpdateDailyAmount(
        categoryKey: movingRefItem.categoryKey,
        dailyAmount: amount,
      );

      if (mounted) setState(() {});

      _showCategoryToast('플랜 카테고리로 이동했어요. 저장 버튼을 눌러야 반영돼요.');

      _clearEditingState();
      return;
    }

    if (id != null && name != null && _editingIsPlan) {
      final exists = vm.draftPlan.any((e) => e.categoryKey == id);

      if (!exists) {
        vm.draftAddCategory(
          isPlan: true,
          categoryKey: id,
          name: name,
          emoji: emoji,
          dailyAmount: amount,
        );
      } else {
        vm.draftUpdateDailyAmount(
          categoryKey: id,
          dailyAmount: amount,
        );
      }

      _clearEditingState();
      return;
    }

    if (id != null) {
      vm.draftUpdateDailyAmount(
        categoryKey: id,
        dailyAmount: amount,
      );
    }

    _clearEditingState();
  }

  void _clearEditingState() {
    _editingCategoryId = null;
    _editingCategoryName = null;
    _editingCategoryEmoji = null;
    _editingIsPlan = false;
    _editingAmount = 1;
    _pendingMoveRefItem = null;
    _pendingMoveTargetIndex = null;
  }

  void _showCategoryToast(String message) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 16,
        right: 16,
        bottom: 110,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard Variable',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 1400), () {
      entry.remove();
    });
  }

  // =========================================================
  // 오버레이
  // =========================================================
  Widget _buildNameSheetOverlay(CategoryEditViewModel vm) {
    final isEditMode = _editingCategoryId != null;

    return Positioned.fill(
      child: Stack(
        children: [
          FadeTransition(
            opacity: _nameScrimFade,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeNameSheet,
              child: Container(color: Colors.black54),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _nameSheetSlide,
              child: CategoryNameModal(
                isEditMode: isEditMode,
                initialName: _editingCategoryName,
                initialEmoji: _editingCategoryEmoji,
                onClose: _closeNameSheet,
                onComplete: (name, emoji) {
                  _onNameComplete(vm, name: name, emoji: emoji);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSheetOverlay(CategoryEditViewModel vm) {
    return Positioned.fill(
      child: Stack(
        children: [
          FadeTransition(
            opacity: _amountScrimFade,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAmountSheet,
              child: Container(color: Colors.black54),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _amountSheetSlide,
              child: CategoryAmountModal(
                initialAmount: _editingAmount,
                onClose: _closeAmountSheet,
                onComplete: (amount) {
                  _onAmountComplete(vm, amount);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Sliver UI Pieces
  // =========================================================
  Widget _planHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '플랜 카테고리',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일일 소비 예산이 있는 카테고리입니다. (레포트 축에 사용)',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _refHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '참고 카테고리',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '자주 쓰는 카테고리를 모아둘 수 있습니다.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton({required VoidCallback onAdd}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: SmallRoundedButton(
          text: '추가',
          backgroundColor: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : AppColors.greyBackground,
          textColor: isDark ? theme.colorScheme.onSurface : AppColors.text,
          onPressed: onAdd,
        ),
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryEditViewModel>(
      builder: (context, vm, _) {
        final dailySum = _calcDailySum(vm.draftPlan);
        final reachDate = vm.projectedGoalDate;
        final theme = Theme.of(context);
        final notice = vm.noticeMessage;
        final rows = _buildRows(vm);

        if (notice != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            _showCategoryToast(notice);
            vm.consumeNoticeMessage();
          });
        }

        return WillPopScope(
          onWillPop: () => _handleBack(vm),
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: BackOnlyAppBar(
              onBack: () async {
                final canPop = await _handleBack(vm);
                if (!mounted) return;
                if (canPop) Navigator.pop(context);
              },
            ),
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: CategoryPlanProgressBox(
                        dailyLimitSum: dailySum,
                        reachDate: reachDate,
                      ),
                    ),

                    SliverReorderableList(
                      itemCount: rows.length,
                      onReorder: (oldIndex, newIndex) {
                        _handleUnifiedReorder(
                          vm,
                          rows: rows,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                      },
                      itemBuilder: (context, index) {
                        final row = rows[index];

                        switch (row.type) {
                          case CategoryEditRowType.planHeader:
                            return Container(
                              key: ValueKey(row.key),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _planHeader(),
                                  if (vm.draftPlan.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      child: Text(
                                        '카테고리가 없습니다. 아래에서 추가해보세요.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );

                          case CategoryEditRowType.planItem:
                            final item = row.planItem!;

                            return PlanCategoryEditTile(
                              key: ValueKey(row.key),
                              item: item,
                              index: index,
                              formatAmount: _formatAmount,
                              onDelete: () =>
                                  vm.draftDeletePlan(item.categoryKey),
                              onTapEditName: () => _openNameForEditPlan(item),
                              onTapEditAmount: () => _openAmountForEdit(item),
                            );

                          case CategoryEditRowType.planAddButton:
                            return Container(
                              key: ValueKey(row.key),
                              child: _addButton(
                                onAdd: () => _openNameForAdd(isPlan: true),
                              ),
                            );

                          case CategoryEditRowType.refHeader:
                            return Container(
                              key: ValueKey(row.key),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: theme.dividerColor,
                                  ),
                                  _refHeader(),
                                  if (vm.draftRef.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      child: Text(
                                        '참고 카테고리가 없습니다.',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );

                          case CategoryEditRowType.refItem:
                            final item = row.refItem!;

                            return RefCategoryEditTile(
                              key: ValueKey(row.key),
                              item: item,
                              index: index,
                              onDelete: () =>
                                  vm.draftRemoveRefByKey(item.categoryKey),
                              onTapEditName: () => _openNameForEditRef(item),
                            );

                          case CategoryEditRowType.refAddButton:
                            return Container(
                              key: ValueKey(row.key),
                              child: _addButton(
                                onAdd: () => _openNameForAdd(isPlan: false),
                              ),
                            );
                        }
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 140)),
                  ],
                ),

                Align(alignment: Alignment.bottomCenter, child: _buildBottomSection(vm)),

                if (_showNameSheet) _buildNameSheetOverlay(vm),
                if (_showAmountSheet) _buildAmountSheetOverlay(vm),
              ],
            ),
          ),
        );
      },
    );
  }
}
