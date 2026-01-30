import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/theme/app_colors.dart';

import '../../../view_model/category/category_edit_view_model.dart';
import '../../../model/category/category_snapshot_item.dart';

import 'category_widgets/category_date_selector.dart';
import 'category_widgets/category_lists_section.dart';
import 'category_widgets/category_name_modal.dart';
import 'category_widgets/category_amount_modal.dart';

enum _UnsavedAction { save, discard, cancel }

class CategoryEditPage extends StatefulWidget {
  const CategoryEditPage({super.key});

  @override
  State<CategoryEditPage> createState() => _CategoryEditPageState();
}

class _CategoryEditPageState extends State<CategoryEditPage> {
  bool _showDateModal = false;
  bool _showNameModal = false;
  bool _showAmountModal = false;

  String? _editingCategoryId;
  String? _editingCategoryName;
  String? _editingCategoryEmoji;
  bool _editingIsPlan = false;

  int _editingAmount = 0;

  CategorySnapshotItem? _pendingMoveRefItem;
  int? _pendingMoveTargetIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryEditViewModel>().loadForSelectedDate();
    });
  }

  // -----------------------------
  // 저장
  // -----------------------------
  Future<void> _save(CategoryEditViewModel vm, {bool popOnSuccess = true}) async {
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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

  // -----------------------------
  // unsaved dialog + date change guard
  // -----------------------------
  Future<_UnsavedAction?> _showUnsavedDialog() {
    return showDialog<_UnsavedAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('저장되지 않은 변경이 있어요'),
        content: const Text(
          '날짜를 이동하면 현재 변경사항이 사라질 수 있어요.\n어떻게 할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _UnsavedAction.cancel),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _UnsavedAction.discard),
            child: const Text('버리기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _UnsavedAction.save),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _tryChangeDate(CategoryEditViewModel vm, DateTime nextDate) async {
    // 변경사항 없으면 바로 이동
    if (!vm.hasUnsavedChanges) {
      await vm.setSelectedDate(nextDate);
      return;
    }

    final action = await _showUnsavedDialog();
    if (!mounted) return;

    if (action == null || action == _UnsavedAction.cancel) return;

    if (action == _UnsavedAction.save) {
      // ✅ 저장 후 날짜 이동 (저장 성공 시에만 이동)
      final ok = await vm.saveDraftForSelectedDate();
      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(vm.error ?? '저장에 실패했습니다.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리가 저장되었습니다.')),
      );

      await vm.setSelectedDate(nextDate);
      return;
    }

    if (action == _UnsavedAction.discard) {
      // ✅ 버리기: 현재 selectedDate 기준으로 다시 로드해서 draft 원복 후 이동
      await vm.loadForSelectedDate();
      await vm.setSelectedDate(nextDate);
      return;
    }
  }

  // -----------------------------
  // 이름/이모지 모달 열기 (추가/수정 공통)
  // -----------------------------
  void _openNameModalForAdd({required bool isPlan}) {
    setState(() {
      _editingCategoryId = null;
      _editingCategoryName = null;
      _editingCategoryEmoji = '💰';
      _editingIsPlan = isPlan;
      _showNameModal = true;
    });
  }

  void _openNameModalForEdit(CategorySnapshotItem item, bool isPlan) {
    setState(() {
      _editingCategoryId = item.categoryId;
      _editingCategoryName = item.name;
      _editingCategoryEmoji = item.emoji;
      _editingIsPlan = isPlan;
      _showNameModal = true;
    });
  }

  void _onNameModalComplete(
      CategoryEditViewModel vm, {
        required String name,
        required String emoji,
      }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    setState(() => _showNameModal = false);

    // ✅ 신규 추가
    if (_editingCategoryId == null) {
      final newId = 'cat_${DateTime.now().millisecondsSinceEpoch}';

      if (_editingIsPlan) {
        // plan은 금액 모달로 이어짐
        setState(() {
          _editingCategoryId = newId;
          _editingCategoryName = trimmed;
          _editingCategoryEmoji = emoji;
          _editingAmount = 0;
          _showAmountModal = true;
        });
        return;
      } else {
        // ref는 바로 추가
        vm.draftAddCategory(
          isPlan: false,
          categoryId: newId,
          name: trimmed,
          emoji: emoji,
        );
        return;
      }
    }

    // ✅ 기존 수정
    vm.draftUpdateMeta(
      categoryId: _editingCategoryId!,
      name: trimmed,
      emoji: emoji,
    );
  }

  // -----------------------------
  // 금액 모달 열기/완료
  // -----------------------------
  void _openAmountModalForEdit(CategorySnapshotItem item) {
    setState(() {
      _editingCategoryId = item.categoryId;
      _editingAmount = item.dailyAmount ?? 0;
      _showAmountModal = true;

      _pendingMoveRefItem = null;
      _pendingMoveTargetIndex = null;
    });
  }

  void _openAmountModalForMoveRefToPlan(CategorySnapshotItem item, int targetIndex) {
    setState(() {
      _pendingMoveRefItem = item;
      _pendingMoveTargetIndex = targetIndex;
      _editingAmount = 0;
      _showAmountModal = true;
    });
  }

  void _onAmountModalComplete(CategoryEditViewModel vm, int amount) {
    if (amount < 0) return;

    setState(() => _showAmountModal = false);

    // ✅ 1) ref→plan 이동 확정
    if (_pendingMoveRefItem != null && _pendingMoveTargetIndex != null) {
      final item = _pendingMoveRefItem!;
      final targetIndex = _pendingMoveTargetIndex!;
      vm.draftMoveRefToPlan(
        categoryId: item.categoryId,
        newIndex: targetIndex,
        dailyAmount: amount,
      );

      _pendingMoveRefItem = null;
      _pendingMoveTargetIndex = null;
      return;
    }

    // ✅ 2) 신규 plan 추가 흐름
    final id = _editingCategoryId;
    final name = _editingCategoryName;
    final emoji = _editingCategoryEmoji ?? '💰';

    if (id != null && name != null && _editingIsPlan) {
      vm.draftAddCategory(
        isPlan: true,
        categoryId: id,
        name: name,
        emoji: emoji,
        dailyAmount: amount,
      );

      _editingCategoryId = null;
      _editingCategoryName = null;
      _editingCategoryEmoji = null;
      _editingIsPlan = false;
      return;
    }

    // ✅ 3) 기존 plan 금액 수정
    if (id != null) {
      vm.draftUpdateDailyAmount(
        categoryId: id,
        dailyAmount: amount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryEditViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const SizedBox.shrink(),
            centerTitle: false,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 날짜 위젯
                          CategoryDateSelector(
                            date: vm.selectedDate,
                            onPrev: () => _tryChangeDate(
                              vm,
                              vm.selectedDate.subtract(const Duration(days: 1)),
                            ),
                            onNext: () => _tryChangeDate(
                              vm,
                              vm.selectedDate.add(const Duration(days: 1)),
                            ),
                            onTapDate: () => setState(() => _showDateModal = true),
                          ),

                          // 리스트 섹션
                          CategoryListsSection(
                            vm: vm,
                            onTapEditName: (item, isPlan) {
                              _openNameModalForEdit(item, isPlan);
                            },
                            onTapEditAmount: (item) {
                              _openAmountModalForEdit(item);
                            },
                            onMoveRefToPlanRequested: (item, targetIndex) {
                              _openAmountModalForMoveRefToPlan(item, targetIndex);
                            },
                            onAddPlan: () => _openNameModalForAdd(isPlan: true),
                            onAddRef: () => _openNameModalForAdd(isPlan: false),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),

                  // 저장 버튼
                  _buildBottomSection(vm),
                ],
              ),

              // 날짜 모달
              if (_showDateModal)
                CategoryDatePickerModal(
                  isOpen: _showDateModal,
                  initialDate: vm.selectedDate,
                  onClose: () => setState(() => _showDateModal = false),
                  onDateSelected: (date) async {
                    setState(() => _showDateModal = false);
                    await _tryChangeDate(vm, date);
                  },
                ),

              // 이름/이모지 모달
              if (_showNameModal)
                CategoryNameModal(
                  isOpen: _showNameModal,
                  initialName: _editingCategoryName,
                  initialEmoji: _editingCategoryEmoji,
                  onClose: () => setState(() => _showNameModal = false),
                  onComplete: (name, emoji) {
                    _onNameModalComplete(vm, name: name, emoji: emoji);
                  },
                ),

              // 금액 모달
              if (_showAmountModal)
                CategoryAmountModal(
                  isOpen: _showAmountModal,
                  initialAmount: _editingAmount,
                  onClose: () => setState(() => _showAmountModal = false),
                  onComplete: (amount) {
                    _onAmountModalComplete(vm, amount);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
