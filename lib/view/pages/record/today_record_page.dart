import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/appbars/back_only_app_bar.dart';
import 'package:sotong_local/component/buttons/period_toggle.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_diary_bottom_sheet.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_diary_section.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_income_bottom_sheets.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_income_section.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_spending_bottom_sheets.dart';
import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_spending_section.dart';
import 'package:sotong_local/view_model/category/add_income_category_view_model.dart';
import 'package:sotong_local/view_model/category/spending_category_view_model.dart';
import 'package:sotong_local/view_model/record/today_income_view_model.dart';
import 'package:sotong_local/view_model/record/today_spending_view_model.dart';

class TodayRecordPage extends StatefulWidget {
  const TodayRecordPage({super.key});

  @override
  State<TodayRecordPage> createState() => _TodayRecordPageState();
}

class _TodayRecordPageState extends State<TodayRecordPage> {
  DateTime? _argDate;
  bool _didInit = false;

  bool _isIncome = false;
  bool _isList = true;
  bool _allowPop = false;

  DateTime get _selectedDate => _argDate ?? DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final date = (args is DateTime) ? args : DateTime.now();

    _argDate = date;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final spendingCategoryVM = context.read<SpendingCategoryViewModel>();
      final incomeCategoryVM = context.read<AddIncomeCategoryViewModel>();
      final spendingVM = context.read<TodaySpendingViewModel>();
      final incomeVM = context.read<TodayIncomeViewModel>();

      await spendingCategoryVM.initForDate(date);
      await incomeCategoryVM.initForDate(date);

      if (!mounted) return;
      await spendingVM.load(date);
      await incomeVM.load(date);
    });

    _didInit = true;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    if (!mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    _showLoading();
    try {
      await action();
    } finally {
      _hideLoading();
    }
  }

  Future<bool> _confirmDiscardRecordDraft() async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dCtx) {
        return AlertDialog(
          content: const Text('저장하지 않고 나가면 수정한 기록이 사라져요.\n그래도 나갈까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('계속 편집'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text(
                '나가기',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
    return res ?? false;
  }

  Future<void> _handleBackPressed({
    required TodayIncomeViewModel incomeVM,
    required TodaySpendingViewModel spendingVM,
  }) async {
    final hasUnsavedChanges =
        incomeVM.hasUnsavedChanges || spendingVM.hasUnsavedChanges;

    if (!hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final leave = await _confirmDiscardRecordDraft();
    if (!leave || !mounted) return;

    incomeVM.discardDraft();
    spendingVM.discardDraft();
    setState(() => _allowPop = true);
    Navigator.pop(context);
  }

  Future<void> _saveAllDrafts({
    required TodayIncomeViewModel incomeVM,
    required TodaySpendingViewModel spendingVM,
  }) async {
    final hasIncomeChanges = incomeVM.hasUnsavedChanges;
    final hasSpendingChanges = spendingVM.hasUnsavedChanges;
    if (!hasIncomeChanges && !hasSpendingChanges) return;

    try {
      await _runWithLoading(() async {
        if (hasIncomeChanges) {
          await incomeVM.saveDraft();
        }
        if (hasSpendingChanges) {
          await spendingVM.saveDraft();
        }
      });
      _snack('오늘 기록이 저장되었어요.');
    } catch (e) {
      _snack('오늘 기록 저장 중 오류가 발생했어요: $e');
    }
  }

  Widget _buildRecordModeDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackBg = isDark ? theme.colorScheme.surface : Colors.grey.shade100;
    final trackBorder = isDark ? theme.dividerColor : Colors.grey.shade300;
    final menuBg = isDark ? theme.colorScheme.surface : Colors.white;
    final selectedText = theme.colorScheme.onSurface;
    final unselectedText = theme.colorScheme.onSurfaceVariant;

    TextStyle itemStyle(bool selected) {
      return TextStyle(
        color: selected ? selectedText : unselectedText,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      );
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: trackBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _isList,
          dropdownColor: menuBg,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: unselectedText,
          ),
          style: TextStyle(
            color: selectedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          items: [
            DropdownMenuItem<bool>(
              value: true,
              child: Text('목록', style: itemStyle(_isList)),
            ),
            DropdownMenuItem<bool>(
              value: false,
              child: Text('일지', style: itemStyle(!_isList)),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _isList = value;
              if (!_isList) _isIncome = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spendingVM = context.watch<TodaySpendingViewModel>();
    final incomeVM = context.watch<TodayIncomeViewModel>();

    final isLoading = spendingVM.isLoading || incomeVM.isLoading;
    final error = spendingVM.error ?? incomeVM.error;
    final hasUnsavedRecordChanges =
        incomeVM.hasUnsavedChanges || spendingVM.hasUnsavedChanges;

    if (isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: BackOnlyAppBar(
          title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
          centerTitle: true,
        ),
        body: SafeArea(child: Center(child: Text('오류: $error'))),
      );
    }

    return PopScope(
      canPop: _allowPop || !hasUnsavedRecordChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPressed(incomeVM: incomeVM, spendingVM: spendingVM);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: BackOnlyAppBar(
          title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
          centerTitle: true,
          onBack: () {
            _handleBackPressed(incomeVM: incomeVM, spendingVM: spendingVM);
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Opacity(
                      opacity: _isList ? 1 : 0.35,
                      child: IgnorePointer(
                        ignoring: !_isList,
                        child: TwoOptionToggle(
                          labels: const ['수입', '소비'],
                          selected: _isIncome ? '수입' : '소비',
                          onChanged: (v) => setState(() {
                            _isIncome = (v == '수입');
                          }),
                          width: 120,
                          height: 34,
                        ),
                      ),
                    ),
                    _buildRecordModeDropdown(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _isIncome
                    ? TodayRecordIncomeSection(
                        vm: incomeVM,
                        hasUnsavedChanges: hasUnsavedRecordChanges,
                        hasEntryChanges: incomeVM.hasEntryChanges,
                        onSave: () => _saveAllDrafts(
                          incomeVM: incomeVM,
                          spendingVM: spendingVM,
                        ),
                        onEdit: (entry) async {
                          final edited =
                              await showTodayRecordEditIncomeBottomSheet(
                                context: context,
                                entry: entry,
                              );

                          if (edited == null || !mounted) return;

                          await incomeVM.updateEntry(
                            entryId: edited.id,
                            categoryKey: edited.categoryKey,
                            category: edited.category,
                            amount: edited.amount,
                            note: edited.note,
                          );
                        },
                        onDelete: (entry) async {
                          await incomeVM.deleteEntry(entry.id);
                        },
                        onAdd: () async {
                          final created =
                              await showTodayRecordAddIncomeBottomSheet(
                                context: context,
                              );

                          if (created == null || !mounted) return;

                          await incomeVM.addEntry(
                            categoryKey: created.categoryKey,
                            category: created.category,
                            amount: created.amount,
                            note: created.note,
                          );
                        },
                      )
                    : (_isList
                          ? TodayRecordSpendingSection(
                              vm: spendingVM,
                              hasUnsavedChanges: hasUnsavedRecordChanges,
                              hasEntryChanges: spendingVM.hasEntryChanges,
                              onSave: () => _saveAllDrafts(
                                incomeVM: incomeVM,
                                spendingVM: spendingVM,
                              ),
                              onEdit: (entry) async {
                                final edited =
                                    await showTodayRecordEditSpendingBottomSheet(
                                      context: context,
                                      entry: entry,
                                    );

                                if (edited == null || !mounted) return;

                                await spendingVM.updateEntry(
                                  entryId: edited.id,
                                  categoryKey: edited.categoryKey,
                                  category: edited.category,
                                  amount: edited.amount,
                                  note: edited.note,
                                );
                                // _snack('저장 버튼을 누르면 수정사항이 반영돼요.');
                              },
                              onDelete: (entry) async {
                                await spendingVM.deleteEntry(entry.id);
                                // _snack('저장 버튼을 누르면 삭제사항이 반영돼요.');
                              },
                              onAdd: () async {
                                final created =
                                    await showTodayRecordAddSpendingBottomSheet(
                                      context: context,
                                    );

                                if (created == null || !mounted) return;

                                await spendingVM.addEntry(
                                  categoryKey: created.categoryKey,
                                  category: created.category,
                                  amount: created.amount,
                                  note: created.note,
                                );
                                // _snack('저장 버튼을 누르면 추가사항이 반영돼요.');
                              },
                            )
                          : TodayRecordDiarySection(
                              vm: spendingVM,
                              hasUnsavedChanges: hasUnsavedRecordChanges,
                              onSave: () => _saveAllDrafts(
                                incomeVM: incomeVM,
                                spendingVM: spendingVM,
                              ),
                              onEdit: () async {
                                try {
                                  final edited =
                                      await showTodayRecordEditDiaryBottomSheet(
                                        context: context,
                                        vm: spendingVM,
                                      );
                                  if (edited == null || !mounted) return;

                                  spendingVM.updateDiaryDraft(
                                    emotion: edited.emotion,
                                    comment: edited.comment,
                                  );
                                } catch (e) {
                                  _snack('일지 수정 중 오류가 발생했어요: $e');
                                }
                              },
                            )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
//
// import 'package:sotong_local/component/appbars/back_only_app_bar.dart';
// import 'package:sotong_local/component/buttons/period_toggle.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_diary_bottom_sheet.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_diary_section.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_income_bottom_sheets.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_income_section.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_spending_bottom_sheets.dart';
// import 'package:sotong_local/view/pages/record/record_widgets/today_record_widget/today_record_spending_section.dart';
// import 'package:sotong_local/view_model/category/add_income_category_view_model.dart';
// import 'package:sotong_local/view_model/category/spending_category_view_model.dart';
// import 'package:sotong_local/view_model/record/today_income_view_model.dart';
// import 'package:sotong_local/view_model/record/today_spending_view_model.dart';
//
// class TodayRecordPage extends StatefulWidget {
//   const TodayRecordPage({super.key});
//
//   @override
//   State<TodayRecordPage> createState() => _TodayRecordPageState();
// }
//
// class _TodayRecordPageState extends State<TodayRecordPage> {
//   DateTime? _argDate;
//   bool _didInit = false;
//
//   bool _isIncome = false;
//   bool _isList = true;
//
//   DateTime get _selectedDate => _argDate ?? DateTime.now();
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_didInit) return;
//
//     final args = ModalRoute.of(context)?.settings.arguments;
//     final date = (args is DateTime) ? args : DateTime.now();
//
//     _argDate = date;
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;
//
//       context.read<SpendingCategoryViewModel>().initForDate(date);
//       context.read<AddIncomeCategoryViewModel>().initForDate(date);
//
//       context.read<TodaySpendingViewModel>().load(date);
//       context.read<TodayIncomeViewModel>().load(date);
//     });
//
//     _didInit = true;
//   }
//
//   void _snack(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(msg)),
//     );
//   }
//
//   Future<void> _waitForOverlaySettled() async {
//     await Future<void>.delayed(Duration.zero);
//     await WidgetsBinding.instance.endOfFrame;
//     await Future<void>.delayed(const Duration(milliseconds: 10));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final spendingVM = context.watch<TodaySpendingViewModel>();
//     final incomeVM = context.watch<TodayIncomeViewModel>();
//
//     final isLoading = spendingVM.isLoading || incomeVM.isLoading;
//     final error = spendingVM.error ?? incomeVM.error;
//
//     if (isLoading) {
//       return const Scaffold(
//         body: SafeArea(
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );
//     }
//
//     if (error != null) {
//       return Scaffold(
//         appBar: BackOnlyAppBar(
//           title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: Center(child: Text('오류: $error')),
//         ),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: BackOnlyAppBar(
//         title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 12),
//
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   TwoOptionToggle(
//                     labels: const ['수입', '소비'],
//                     selected: _isIncome ? '수입' : '소비',
//                     onChanged: (v) => setState(() {
//                       _isIncome = (v == '수입');
//                       if (_isIncome) _isList = true;
//                     }),
//                     width: 120,
//                     height: 34,
//                   ),
//                 ],
//               ),
//             ),
//
//             if (!_isIncome) ...[
//               const SizedBox(height: 12),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TwoOptionToggle(
//                       labels: const ['목록', '일지'],
//                       selected: _isList ? '목록' : '일지',
//                       onChanged: (v) => setState(() => _isList = (v == '목록')),
//                       width: 120,
//                       height: 34,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//
//             const SizedBox(height: 20),
//
//             Expanded(
//               child: _isIncome
//                   ? TodayRecordIncomeSection(
//                 vm: incomeVM,
//                 onEdit: (entry) async {
//                   final edited = await showTodayRecordEditIncomeBottomSheet(
//                     context: context,
//                     entry: entry,
//                   );
//
//                   if (edited == null) return;
//                   if (!mounted) return;
//
//                   await _waitForOverlaySettled();
//
//                   try {
//                     await incomeVM.updateEntry(
//                       entryId: edited.id,
//                       categoryKey: edited.categoryKey,
//                       category: edited.category,
//                       amount: edited.amount,
//                       note: edited.note,
//                     );
//                     _snack('수입 항목이 수정되었어요.');
//                   } catch (e) {
//                     _snack('수입 수정 중 오류가 발생했어요: $e');
//                   }
//                 },
//                 onDelete: (entry) async {
//                   try {
//                     await incomeVM.deleteEntry(entry.id);
//                     _snack('수입 항목이 삭제되었어요.');
//                   } catch (e) {
//                     _snack('수입 삭제 중 오류가 발생했어요: $e');
//                   }
//                 },
//                 onAdd: () async {
//                   final created = await showTodayRecordAddIncomeBottomSheet(
//                     context: context,
//                   );
//
//                   if (created == null) return;
//                   if (!mounted) return;
//
//                   await _waitForOverlaySettled();
//
//                   try {
//                     await incomeVM.addEntry(
//                       categoryKey: created.categoryKey,
//                       category: created.category,
//                       amount: created.amount,
//                       note: created.note,
//                     );
//                     _snack('수입 항목이 추가되었어요.');
//                   } catch (e) {
//                     _snack('수입 저장 중 오류가 발생했어요: $e');
//                   }
//                 },
//               )
//                   : (_isList
//                   ? TodayRecordSpendingSection(
//                 vm: spendingVM,
//                 onEdit: (entry) async {
//                   final edited =
//                   await showTodayRecordEditSpendingBottomSheet(
//                     context: context,
//                     entry: entry,
//                   );
//
//                   if (edited == null) return;
//                   if (!mounted) return;
//
//                   await _waitForOverlaySettled();
//
//                   try {
//                     await spendingVM.updateEntry(
//                       entryId: edited.id,
//                       categoryKey: edited.categoryKey,
//                       category: edited.category,
//                       amount: edited.amount,
//                       note: edited.note,
//                     );
//                     _snack('소비 항목이 수정되었어요.');
//                   } catch (e) {
//                     _snack('소비 수정 중 오류가 발생했어요: $e');
//                   }
//                 },
//                 onDelete: (entry) async {
//                   try {
//                     await spendingVM.deleteEntry(entry.id);
//                     _snack('소비 항목이 삭제되었어요.');
//                   } catch (e) {
//                     _snack('소비 삭제 중 오류가 발생했어요: $e');
//                   }
//                 },
//                 onAdd: () async {
//                   final created =
//                   await showTodayRecordAddSpendingBottomSheet(
//                     context: context,
//                   );
//
//                   if (created == null) return;
//                   if (!mounted) return;
//
//                   await _waitForOverlaySettled();
//
//                   try {
//                     await spendingVM.addEntry(
//                       categoryKey: created.categoryKey,
//                       category: created.category,
//                       amount: created.amount,
//                       note: created.note,
//                     );
//                     _snack('소비 항목이 추가되었어요.');
//                   } catch (e) {
//                     _snack('소비 저장 중 오류가 발생했어요: $e');
//                   }
//                 },
//               )
//                   : TodayRecordDiarySection(
//                 vm: spendingVM,
//                 onEdit: () async {
//                   try {
//                     await showTodayRecordEditDiaryBottomSheet(
//                       context: context,
//                       vm: spendingVM,
//                     );
//                   } catch (e) {
//                     _snack('일지 수정 중 오류가 발생했어요: $e');
//                   }
//                 },
//               )),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
