import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view/pages/record/record_widgets/addIncome_widget/add_income_input_entry.dart';
import 'package:sotong_local/view/pages/record/record_widgets/spending_widget/spending_input_entry.dart';

import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/category/spending_category_view_model.dart';
import '../../../view_model/category/add_income_category_view_model.dart';
import '../../../view_model/record/record_add_income_view_model.dart';
import '../../../view_model/record/record_spending_view_model.dart';
import '../../../view_model/home/home_view_model.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  bool _didInit = false;
  late DateTime _selectedDate;

  /// true: 소비, false: 수입
  bool _isSpending = true;

  /// 소비없음 체크
  bool _noSpendingChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    _selectedDate = (args is DateTime) ? args : DateTime.now();

    context.read<SpendingCategoryViewModel>().initForDate(_selectedDate);
    context.read<AddIncomeCategoryViewModel>().initForDate(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordSpendingViewModel>().resetSpending();
      context.read<RecordAddIncomeViewModel>().resetIncome();
      if (mounted) {
        setState(() {
          _noSpendingChecked = false;
        });
      }
    });

    _didInit = true;
  }

  @override
  Widget build(BuildContext context) {
    final spendingVM = context.watch<RecordSpendingViewModel>();
    final incomeVM = context.watch<RecordAddIncomeViewModel>();

    final spendingCatVM = context.watch<SpendingCategoryViewModel>();
    final incomeCatVM = context.watch<AddIncomeCategoryViewModel>();

    final bool isCategoryLoading =
    _isSpending ? spendingCatVM.loading : incomeCatVM.loading;

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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  TwoOptionToggle(
                    labels: const ['수입', '소비'],
                    selected: _isSpending ? '소비' : '수입',
                    onChanged: (v) {
                      setState(() {
                        _isSpending = v == '소비';
                      });
                    },
                    width: 106,
                    height: 30,
                  ),
                  const Spacer(),
                  if (_isSpending)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _noSpendingChecked,
                            onChanged: (v) {
                              final checked = v ?? false;
                              setState(() => _noSpendingChecked = checked);
                              context.read<RecordSpendingViewModel>().setNoSpending(checked);
                            },
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            activeColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            final checked = !_noSpendingChecked;
                            setState(() => _noSpendingChecked = checked);
                            context.read<RecordSpendingViewModel>().setNoSpending(checked);
                          },
                          child: Text(
                            '무지출',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: _isSpending
                        ? _buildSpendingContent(spendingVM)
                        : _buildIncomeContent(incomeVM),
                  ),

                  if (_isSpending && _noSpendingChecked)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.6),
                        ),
                      ),
                    ),

                  if (isCategoryLoading)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: AppSpacing.fieldSpacing),
                    ParagraphText(text: _isSpending ? '총 소비 금액' : '총 수입 금액'),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    _isSpending
                        ? Selector<RecordSpendingViewModel, String>(
                      selector: (_, vm) => vm.formattedTotal,
                      builder: (_, formattedTotal, __) {
                        return ParagraphText(
                          text: '$formattedTotal원',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        );
                      },
                    )
                        : Selector<RecordAddIncomeViewModel, String>(
                      selector: (_, vm) => vm.formattedTotal,
                      builder: (_, formattedTotal, __) {
                        return ParagraphText(
                          text: '$formattedTotal원',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.fieldSpacing),
                  ],
                ),
              ),
            ),

            CustomButton(
              text: '다음 단계',
              enabled: _isSpending
                  ? (_noSpendingChecked || spendingVM.canProceedToNextStep)
                  : incomeVM.canProceedToNextStep,
              onPressed: () async {
                final hasSpendingOrNoSpending =
                    _noSpendingChecked || spendingVM.canProceedToNextStep;

                if (_isSpending) {
                  Navigator.pushNamed(
                    context,
                    '/record_diary',
                    arguments: _selectedDate,
                  );
                  return;
                }

                if (!hasSpendingOrNoSpending) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('소비를 입력하거나 무지출을 체크해주세요.'),
                    ),
                  );
                  return;
                }

                try {
                  await incomeVM.saveAllForDate(_selectedDate);

                  final totalIncome = incomeVM.totalIncome;
                  if (totalIncome > 0 && mounted) {
                    context.read<HomeViewModel>().registerExtraIncome(
                      _selectedDate,
                      totalIncome,
                    );
                  }

                  incomeVM.resetApplyStates();

                  if (!mounted) return;

                  Navigator.pushNamed(
                    context,
                    '/record_diary',
                    arguments: _selectedDate,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('수입 저장 중 문제가 발생했어요: $e'),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingContent(RecordSpendingViewModel vm) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...vm.spendingEntries.map((entry) {
            return SpendingInputEntry(
              key: ObjectKey(entry),
              entry: entry,
              onDelete: () => vm.removeEntryByRef(entry),
              enableDismissible: true,
            );
          }).toList(),
          const SizedBox(height: 12),
          SmallRoundedButton(
            text: '추가',
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : AppColors.greyBackground,
            textColor: Theme.of(context).colorScheme.onSurface,
            onPressed: vm.addEntry,
          ),
          const SizedBox(height: AppSpacing.bottomSpacing),
        ],
      ),
    );
  }

  Widget _buildIncomeContent(RecordAddIncomeViewModel vm) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...vm.incomeEntries.map((entry) {
            return AddIncomeInputEntry(
              key: ObjectKey(entry),
              entry: entry,
              onDelete: () => vm.removeEntryByRef(entry),
              enableDismissible: true,
            );
          }).toList(),
          const SizedBox(height: 12),
          SmallRoundedButton(
            text: '추가',
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : AppColors.greyBackground,
            textColor: Theme.of(context).colorScheme.onSurface,
            onPressed: vm.addEntry,
          ),
          const SizedBox(height: AppSpacing.bottomSpacing),
        ],
      ),
    );
  }
}