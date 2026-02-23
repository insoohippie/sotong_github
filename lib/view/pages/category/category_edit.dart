import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/theme/app_colors.dart';

import '../../../model/category/ref_category_item.dart';
import '../../../model/category/category_edit_item.dart';
import '../../../view_model/category/category_edit_view_model.dart';

import 'category_widgets/category_lists_section.dart';
import 'category_widgets/category_name_modal.dart';
import 'category_widgets/category_amount_modal.dart';

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage>
    with TickerProviderStateMixin {
  // ========= UI flags =========
  bool _showNameSheet = false;
  bool _showAmountSheet = false;

  // ========= Name sheet controller =========
  late final AnimationController _nameSheetCtrl;
  late final Animation<Offset> _nameSheetSlide;
  late final Animation<double> _nameScrimFade;

  // ========= Amount sheet controller =========
  late final AnimationController _amountSheetCtrl;
  late final Animation<Offset> _amountSheetSlide;
  late final Animation<double> _amountScrimFade;

  // ========= Editing state =========
  String? _editingCategoryId;
  String? _editingCategoryName;
  String? _editingCategoryEmoji;
  bool _editingIsPlan = false; // plan vs ref
  int _editingAmount = 1;

  // ✅ (ref->plan move은 지금 미구현이라 남겨만 둠)
  CategoryEditItem? _pendingMoveRefItem;
  int? _pendingMoveTargetIndex;

  @override
  void initState() {
    super.initState();

    // name sheet anim
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

    // amount sheet anim
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.grey.shade300, width: 1),
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
  // ✅ 시트 안전 처리: 동시에 안 열리게
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
    // ✅ amount가 열려있으면 닫고 열기 (동시 오픈 방지)
    if (_showAmountSheet) {
      await _closeAmountSheet(setFalse: true);
    }
    if (!mounted) return;

    setState(() => _showNameSheet = true);
    _nameSheetCtrl.forward(from: 0);
  }

  Future<void> _openAmountSheet() async {
    // ✅ name이 열려있으면 닫고 열기 (동시 오픈 방지)
    if (_showNameSheet) {
      await _closeNameSheet(setFalse: true);
    }
    if (!mounted) return;

    setState(() => _showAmountSheet = true);
    _amountSheetCtrl.forward(from: 0);
  }

  // =========================================================
  // 이름/이모지 시트 열기 (추가/수정)
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

  // =========================================================
  // 이름/이모지 완료
  // - ✅ Plan 신규 추가: 이름/이모지 받고 -> 금액 시트 띄움
  // - ✅ Plan 수정: 이름/이모지 업데이트만
  // - ✅ Ref 신규/수정: 금액 없음
  // =========================================================
  void _onNameComplete(
      CategoryEditViewModel vm, {
        required String name,
        required String emoji,
      }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // 시트 닫기
    await _closeNameSheet(setFalse: true);
    if (!mounted) return;

    // ✅ 신규 추가
    if (_editingCategoryId == null) {
      // ✅ Plan 신규: 금액 시트로 이어서
      if (_editingIsPlan) {
        final newKey = 'cat_${DateTime.now().millisecondsSinceEpoch}';
        _editingCategoryId = newKey;
        _editingCategoryName = trimmed;
        _editingCategoryEmoji = emoji;
        _editingAmount = 1;

        // ✅ 금액 시트 오픈
        await _openAmountSheet();
        return;
      }

      // ✅ Ref 신규: 바로 draft 반영 (금액 없음)
      vm.draftAddRef(name: trimmed, emoji: emoji);
      _clearEditingState();
      return;
    }

    // ✅ 기존 수정
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

  // =========================================================
  // 금액 시트 열기/완료
  // =========================================================
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

    // ✅ ref->plan move 미구현 (지금 호출될 일 없음)
    if (_pendingMoveRefItem != null && _pendingMoveTargetIndex != null) {
      _pendingMoveRefItem = null;
      _pendingMoveTargetIndex = null;
      _clearEditingState();
      return;
    }

    final id = _editingCategoryId;
    final name = _editingCategoryName;
    final emoji = (_editingCategoryEmoji ?? '💰');

    // ✅ Plan 신규 추가(이름 시트에서 newKey 세팅 후 들어오는 케이스)
    if (id != null && name != null && _editingIsPlan) {
      // 신규인지/수정인지 구분: draft에 이미 있으면 update, 없으면 add
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

    // ✅ 기존 plan 금액 수정
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
  // Overlay builders
  // =========================================================
  Widget _buildNameSheetOverlay(CategoryEditViewModel vm) {
    final isEditMode = _editingCategoryId != null;

    return Positioned.fill(
      child: Stack(
        children: [
          // scrim
          FadeTransition(
            opacity: _nameScrimFade,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeNameSheet,
              child: Container(color: Colors.black54),
            ),
          ),

          // sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _nameSheetSlide,
              child: CategoryNameModal(
                // ✅ 네 프로젝트에서 isOpen 제거해도 됨. 대신 isEditMode는 넘겨줘야 함.
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
          // scrim
          FadeTransition(
            opacity: _amountScrimFade,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAmountSheet,
              child: Container(color: Colors.black54),
            ),
          ),

          // sheet
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
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryEditViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const BackOnlyAppBar(),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CategoryListsSection(
                            vm: vm,
                            onTapEditNamePlan: (item) =>
                                _openNameForEditPlan(item),
                            onTapEditAmountPlan: (item) =>
                                _openAmountForEdit(item),
                            onTapEditNameRef: (refItem) =>
                                _openNameForEditRef(refItem),
                            onAddPlan: () => _openNameForAdd(isPlan: true),
                            onAddRef: () => _openNameForAdd(isPlan: false),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomSection(vm),
                ],
              ),

              // ✅ Name sheet overlay (애니메이션 + scrim)
              if (_showNameSheet) _buildNameSheetOverlay(vm),

              // ✅ Amount sheet overlay (애니메이션 + scrim)
              if (_showAmountSheet) _buildAmountSheetOverlay(vm),
            ],
          ),
        );
      },
    );
  }
}
