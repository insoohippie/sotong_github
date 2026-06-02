import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/theme/app_colors.dart';

// ✅ 너 프로젝트에 이미 있는 텍스트/버튼 스타일 쓰면 import 연결해서 교체 가능
// import '../../../component/theme/app_text_styles.dart';
// import '../../../component/buttons/small_rounded_button.dart';

import '../../../model/category/ref_category_item.dart';
import '../../../model/category/category_edit_item.dart';
import '../../../view_model/category/category_edit_view_model.dart';

// ✅ 모달 2개는 그대로 유지
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

  CategoryEditItem? _pendingMoveRefItem;
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
    ).animate(CurvedAnimation(parent: _nameSheetCtrl, curve: Curves.easeOut));
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
    ).animate(CurvedAnimation(parent: _amountSheetCtrl, curve: Curves.easeOut));
    _amountScrimFade = CurvedAnimation(
      parent: _amountSheetCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryEditViewModel>().initOnce();
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

  DateTime? _calcReachDate(int dailySum, int targetAmount) {
    if (dailySum <= 0 || targetAmount <= 0) return null;
    final daysToReach = (targetAmount / dailySum).ceil();
    return DateTime.now().add(Duration(days: daysToReach));
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
      if (popOnSuccess) Navigator.pop(context);
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
    if (trimmed.isEmpty) return;

    await _closeNameSheet(setFalse: true);
    if (!mounted) return;

    if (_editingCategoryId == null) {
      if (_editingIsPlan) {
        final newKey = 'cat_${DateTime.now().millisecondsSinceEpoch}';
        _editingCategoryId = newKey;
        _editingCategoryName = trimmed;
        _editingCategoryEmoji = emoji;
        _editingAmount = 1;

        await _openAmountSheet();
        return;
      }

      vm.draftAddRef(name: trimmed, emoji: emoji);
      _clearEditingState();
      return;
    }

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

    if (_pendingMoveRefItem != null && _pendingMoveTargetIndex != null) {
      _pendingMoveRefItem = null;
      _pendingMoveTargetIndex = null;
      _clearEditingState();
      return;
    }

    final id = _editingCategoryId;
    final name = _editingCategoryName;
    final emoji = (_editingCategoryEmoji ?? '💰');

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

  Widget _planSliverTile({
    required Key key,
    required CategoryEditItem item,
    required int index,
    required VoidCallback onDelete,
    required VoidCallback onTapEditName,
    required VoidCallback onTapEditAmount,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? theme.colorScheme.surface : Colors.white;
    final tileBorder =
        isDark ? theme.dividerColor : Colors.grey.shade200;
    final dragColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      key: key, // ✅ sliver reorderable이 추적할 key
      child: Dismissible(
        key: ValueKey('plan-dismiss-${item.categoryKey}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tileBorder),
          ),
          child: Material(
            type: MaterialType.transparency, // ✅ 핵심: Material ancestor 제공
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ReorderableDragStartListener(
                index: index,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_handle, color: dragColor),
                    const SizedBox(width: 8),
                    Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onTapEditName,
                      child: Text(
                        item.name,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onTapEditAmount,
                    child: Text(
                      _formatAmount(item.dailyAmount ?? 0),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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

  Widget _refSliverTile({
    required Key key,
    required RefCategoryItem item,
    required int index,
    required VoidCallback onDelete,
    required VoidCallback onTapEditName,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isDark ? theme.colorScheme.surface : Colors.white;
    final tileBorder =
        isDark ? theme.dividerColor : Colors.grey.shade200;
    final dragColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      key: key,
      child: Dismissible(
        key: ValueKey('ref-dismiss-${item.categoryKey}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tileBorder),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: ReorderableDragStartListener(
                index: index,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drag_handle, color: dragColor),
                    const SizedBox(width: 8),
                    Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              title: GestureDetector(
                onTap: onTapEditName,
                child: Text(
                  item.name,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
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
        final reachDate = _calcReachDate(dailySum, vm.targetAmount);

        final theme = Theme.of(context);

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

                    // PLAN
                    SliverToBoxAdapter(child: _planHeader()),
                    if (vm.draftPlan.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: Text(
                            '카테고리가 없습니다. 아래에서 추가해보세요.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverReorderableList(
                        itemCount: vm.draftPlan.length,
                        onReorder: (oldIndex, newIndex) {
                          final items = vm.draftPlan;
                          final keys = items.map((e) => e.categoryKey).toList();
                          final newKeys = _reorderKeys(keys: keys, oldIndex: oldIndex, newIndex: newIndex);
                          vm.draftReorderPlanByKeys(newKeys);
                        },
                        itemBuilder: (context, index) {
                          final item = vm.draftPlan[index];
                          return _planSliverTile(
                            key: ValueKey('plan-${item.categoryKey}'),
                            item: item,
                            index: index,
                            onDelete: () => vm.draftDeletePlan(item.categoryKey),
                            onTapEditName: () => _openNameForEditPlan(item),
                            onTapEditAmount: () => _openAmountForEdit(item),
                          );
                        },
                      ),
                    SliverToBoxAdapter(child: _addButton(onAdd: () => _openNameForAdd(isPlan: true))),

                    SliverToBoxAdapter(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor,
                      ),
                    ),

                    // REF
                    SliverToBoxAdapter(child: _refHeader()),
                    if (vm.draftRef.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          child: Text(
                            '참고 카테고리가 없습니다.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverReorderableList(
                        itemCount: vm.draftRef.length,
                        onReorder: (oldIndex, newIndex) {
                          final items = vm.draftRef;
                          final keys = items.map((e) => e.categoryKey).toList();
                          final newKeys = _reorderKeys(keys: keys, oldIndex: oldIndex, newIndex: newIndex);
                          vm.draftReorderRefByKeys(newKeys);
                        },
                        itemBuilder: (context, index) {
                          final item = vm.draftRef[index];
                          return _refSliverTile(
                            key: ValueKey('ref-${item.categoryKey}'),
                            item: item,
                            index: index,
                            onDelete: () => vm.draftRemoveRefByKey(item.categoryKey),
                            onTapEditName: () => _openNameForEditRef(item),
                          );
                        },
                      ),
                    SliverToBoxAdapter(child: _addButton(onAdd: () => _openNameForAdd(isPlan: false))),

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