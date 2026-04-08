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

  DateTime get _selectedDate => _argDate ?? DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final date = (args is DateTime) ? args : DateTime.now();

    _argDate = date;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<SpendingCategoryViewModel>().initForDate(date);
      context.read<AddIncomeCategoryViewModel>().initForDate(date);

      context.read<TodaySpendingViewModel>().load(date);
      context.read<TodayIncomeViewModel>().load(date);
    });

    _didInit = true;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _waitForOverlaySettled() async {
    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    final spendingVM = context.watch<TodaySpendingViewModel>();
    final incomeVM = context.watch<TodayIncomeViewModel>();

    final isLoading = spendingVM.isLoading || incomeVM.isLoading;
    final error = spendingVM.error ?? incomeVM.error;

    if (isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: BackOnlyAppBar(
          title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(child: Text('오류: $error')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BackOnlyAppBar(
        title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TwoOptionToggle(
                    labels: const ['수입', '소비'],
                    selected: _isIncome ? '수입' : '소비',
                    onChanged: (v) => setState(() {
                      _isIncome = (v == '수입');
                      if (_isIncome) _isList = true;
                    }),
                    width: 120,
                    height: 34,
                  ),
                ],
              ),
            ),

            if (!_isIncome) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TwoOptionToggle(
                      labels: const ['목록', '일지'],
                      selected: _isList ? '목록' : '일지',
                      onChanged: (v) => setState(() => _isList = (v == '목록')),
                      width: 120,
                      height: 34,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            Expanded(
              child: _isIncome
                  ? TodayRecordIncomeSection(
                vm: incomeVM,
                onEdit: (entry) async {
                  final edited = await showTodayRecordEditIncomeBottomSheet(
                    context: context,
                    entry: entry,
                  );

                  if (edited == null) return;
                  if (!mounted) return;

                  await _waitForOverlaySettled();

                  try {
                    await incomeVM.updateEntry(
                      entryId: edited.id,
                      categoryKey: edited.categoryKey,
                      category: edited.category,
                      amount: edited.amount,
                      note: edited.note,
                    );
                    _snack('수입 항목이 수정되었어요.');
                  } catch (e) {
                    _snack('수입 수정 중 오류가 발생했어요: $e');
                  }
                },
                onDelete: (entry) async {
                  try {
                    await incomeVM.deleteEntry(entry.id);
                    _snack('수입 항목이 삭제되었어요.');
                  } catch (e) {
                    _snack('수입 삭제 중 오류가 발생했어요: $e');
                  }
                },
                onAdd: () async {
                  final created = await showTodayRecordAddIncomeBottomSheet(
                    context: context,
                  );

                  if (created == null) return;
                  if (!mounted) return;

                  await _waitForOverlaySettled();

                  try {
                    await incomeVM.addEntry(
                      categoryKey: created.categoryKey,
                      category: created.category,
                      amount: created.amount,
                      note: created.note,
                    );
                    _snack('수입 항목이 추가되었어요.');
                  } catch (e) {
                    _snack('수입 저장 중 오류가 발생했어요: $e');
                  }
                },
              )
                  : (_isList
                  ? TodayRecordSpendingSection(
                vm: spendingVM,
                onEdit: (entry) async {
                  final edited =
                  await showTodayRecordEditSpendingBottomSheet(
                    context: context,
                    entry: entry,
                  );

                  if (edited == null) return;
                  if (!mounted) return;

                  await _waitForOverlaySettled();

                  try {
                    await spendingVM.updateEntry(
                      entryId: edited.id,
                      categoryKey: edited.categoryKey,
                      category: edited.category,
                      amount: edited.amount,
                      note: edited.note,
                    );
                    _snack('소비 항목이 수정되었어요.');
                  } catch (e) {
                    _snack('소비 수정 중 오류가 발생했어요: $e');
                  }
                },
                onDelete: (entry) async {
                  try {
                    await spendingVM.deleteEntry(entry.id);
                    _snack('소비 항목이 삭제되었어요.');
                  } catch (e) {
                    _snack('소비 삭제 중 오류가 발생했어요: $e');
                  }
                },
                onAdd: () async {
                  final created =
                  await showTodayRecordAddSpendingBottomSheet(
                    context: context,
                  );

                  if (created == null) return;
                  if (!mounted) return;

                  await _waitForOverlaySettled();

                  try {
                    await spendingVM.addEntry(
                      categoryKey: created.categoryKey,
                      category: created.category,
                      amount: created.amount,
                      note: created.note,
                    );
                    _snack('소비 항목이 추가되었어요.');
                  } catch (e) {
                    _snack('소비 저장 중 오류가 발생했어요: $e');
                  }
                },
              )
                  : TodayRecordDiarySection(
                vm: spendingVM,
                onEdit: () async {
                  try {
                    await showTodayRecordEditDiaryBottomSheet(
                      context: context,
                      vm: spendingVM,
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
    );
  }
}