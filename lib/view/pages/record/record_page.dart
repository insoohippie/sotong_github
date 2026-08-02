import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sotong/view/pages/record/record_widgets/addIncome_widget/add_income_input_entry.dart';
import 'package:sotong/view/pages/record/record_widgets/spending_widget/spending_input_entry.dart';

import '../../../component/wrappers/keyboard_dismiss_scope.dart';
import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/category/spending_category_view_model.dart';
import '../../../view_model/category/add_income_category_view_model.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../../view_model/record/record_add_income_view_model.dart';
import '../../../view_model/record/record_spending_view_model.dart';

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

  /// 수입만 바로 저장 중인지
  bool _isSavingIncomeOnly = false;

  /// 기존 수입 기록을 불러오는 중인지
  bool _isLoadingInitialData = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInit) {
      return;
    }

    _didInit = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    _selectedDate =
    args is DateTime ? args : DateTime.now();

    context
        .read<SpendingCategoryViewModel>()
        .initForDate(_selectedDate);

    context
        .read<AddIncomeCategoryViewModel>()
        .initForDate(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _initializeRecordInputs();
    });
  }

  Future<void> _initializeRecordInputs() async {
    setState(() {
      _isLoadingInitialData = true;
      _noSpendingChecked = false;
    });

    final spendingVM =
    context.read<RecordSpendingViewModel>();

    final incomeVM =
    context.read<RecordAddIncomeViewModel>();

    /*
   * 소비 입력창은 기존처럼 빈 화면으로 초기화
   * 수입 입력창만 선택 날짜의 기존 데이터를 불러옴
   */
    spendingVM.resetSpending();

    try {
      await incomeVM.loadIncomeForDate(_selectedDate);
    } catch (e) {
      /*
     * 불러오기에 실패했을 때 이전 화면의 입력값이 남지 않도록
     * 빈 수입 입력창으로 초기화
     */
      incomeVM.resetIncome();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '기존 수입 기록을 불러오지 못했어요: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitialData = false;
        });
      }
    }
  }
  Future<void> _saveIncomeOnly(
      RecordAddIncomeViewModel incomeVM,
      ) async {
    if (_isSavingIncomeOnly) {
      return;
    }

    setState(() {
      _isSavingIncomeOnly = true;
    });

    try {
      /*
   * saveAllForDate()가 호출되면 originalTotalIncome이 갱신되므로
   * 저장 전에 차액을 먼저 계산해야 함
   */
      final incomeDifference =
          incomeVM.incomeAmountDifference;

      await incomeVM.saveAllForDate(_selectedDate);

      if (!mounted) {
        return;
      }

      final homeVM = context.read<HomeViewModel>();

      /*
   * 기존 5만 원이 그대로인 경우 difference는 0
   * 기존 5만 원에 새 3만 원을 추가한 경우 difference는 3만
   */
      if (incomeDifference > 0) {
        homeVM.registerExtraIncome(
          _selectedDate,
          incomeDifference,
        );
      }

      /*
     * HomeViewModel이 기존 월 데이터를 메모리에 가지고 있을 수 있으므로
     * 월 캐시를 비운 뒤 저장한 날짜를 다시 불러온다.
     */
      homeVM.clearMemoryMonthlyCache();

      await homeVM.loadDailySummary(
        _selectedDate,
      );

      incomeVM.resetApplyStates();

      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home_tab_navigator',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '수입 저장 중 오류가 발생했어요: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingIncomeOnly = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spendingVM = context.watch<RecordSpendingViewModel>();
    final incomeVM = context.watch<RecordAddIncomeViewModel>();

    final spendingCatVM = context.watch<SpendingCategoryViewModel>();
    final incomeCatVM = context.watch<AddIncomeCategoryViewModel>();

    final bool isCategoryLoading =
        _isLoadingInitialData ||
            (_isSpending
                ? spendingCatVM.loading
                : incomeCatVM.loading);

    final hasIncomeInput = incomeVM.hasIncomeInput;
    final hasSpendingInput = spendingVM.hasSpendingInput;

    final hasAnyInput = hasIncomeInput || hasSpendingInput;

    /// 수입 탭에서 수입만 저장하려는 경우
    final shouldSaveIncomeOnly =
        !_isSpending &&
            hasIncomeInput &&
            !hasSpendingInput;

    /// 현재 선택된 탭을 기준으로 버튼 활성화
    ///
    /// 소비 탭:
    ///   소비 입력 또는 무지출 선택이 있어야 활성화
    ///
    /// 수입 탭:
    ///   수입 또는 소비 입력이 있으면 활성화
    final canPressButton = _isSpending
        ? hasSpendingInput
        : hasAnyInput;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: BackOnlyAppBar(
        title: DateFormat('yyyy년 M월 d일').format(_selectedDate),
        centerTitle: true,
      ),
      body: KeyboardDismissScope(
        child: SafeArea(
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
                text: _isSavingIncomeOnly
                    ? '저장 중...'
                    : shouldSaveIncomeOnly
                    ? '수입 저장하기'
                    : '다음 단계',
                enabled:
                canPressButton &&
                    !_isSavingIncomeOnly &&
                    !isCategoryLoading,
                onPressed: () async {
                  try {
                    /*
       * 소비 탭에서는 기존 수입만 있다고
       * 버튼이 활성화되지 않도록 처리
       */
                    if (_isSpending && !hasSpendingInput) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '소비를 입력하거나 무지출을 체크해주세요.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (!_isSpending && !hasAnyInput) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '수입이나 소비 내역을 입력해주세요.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (hasIncomeInput &&
                        incomeVM.hasInvalidCategorySelection) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '카테고리가 선택되지 않은 수입 항목이 있습니다.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (hasSpendingInput &&
                        spendingVM.hasInvalidCategorySelection) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '카테고리가 선택되지 않은 소비 항목이 있습니다.',
                          ),
                        ),
                      );
                      return;
                    }

                    /*
       * 수입 탭에서 수입만 입력된 경우에만
       * 감정 화면 없이 바로 저장
       */
                    if (shouldSaveIncomeOnly) {
                      await _saveIncomeOnly(incomeVM);
                      return;
                    }

                    /*
       * 소비 입력 또는 무지출 기록이 있으면
       * 감정 입력 페이지로 이동
       */
                    if (!mounted) {
                      return;
                    }

                    Navigator.pushNamed(
                      context,
                      '/record_diary',
                      arguments: _selectedDate,
                    );
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '기록 처리 중 문제가 발생했어요: '
                              '${e.toString().replaceFirst('Exception: ', '')}',
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: AppSpacing.bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingContent(RecordSpendingViewModel vm) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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