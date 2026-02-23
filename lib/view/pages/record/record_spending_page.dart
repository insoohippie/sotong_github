import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/category/spending_category_view_model.dart';
import '../../../view_model/record/record_view_model.dart';

import 'record_widgets/spending_input_entry.dart';

class RecordSpendingPage extends StatefulWidget {
  const RecordSpendingPage({super.key});

  @override
  State<RecordSpendingPage> createState() => _RecordSpendingPageState();
}

class _RecordSpendingPageState extends State<RecordSpendingPage> {
  bool _didInit = false;
  late DateTime _selectedDate;

  /// true: 소비, false: 수입
  bool _isSpending = true;

  /// 소비없음 체크 시 다음 단계 버튼 활성화
  bool _noSpendingChecked = false;

  /// 수입 토글용 항목 (소비와 동일 컴포넌트 재사용)
  final List<Map<String, dynamic>> _incomeEntries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    _selectedDate = (args is DateTime) ? args : DateTime.now();

    context.read<SpendingCategoryViewModel>().initForDate(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordViewModel>().resetSpending();
    });

    _addIncomeEntry();

    _didInit = true;
  }

  @override
  void dispose() {
    for (final e in _incomeEntries) {
      (e['amountController'] as TextEditingController?)?.dispose();
      (e['noteController'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  void _addIncomeEntry() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    setState(() {
      _incomeEntries.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'category': '',
        'categoryKey': null,
        'categorySource': null,
        'categoryEmoji': null,
        'amountController': amountController,
        'noteController': noteController,
        'amount': 0.0,
        'note': '',
      });
    });
  }

  void _removeIncomeEntry(Map<String, dynamic> entry) {
    setState(() {
      (entry['amountController'] as TextEditingController?)?.dispose();
      (entry['noteController'] as TextEditingController?)?.dispose();
      _incomeEntries.remove(entry);
    });
  }

  double get _incomeTotal => _incomeEntries.fold<double>(
    0.0,
        (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0),
  );

  String get _formattedIncomeTotal =>
      NumberFormat('#,###').format(_incomeTotal.round());

  @override
  Widget build(BuildContext context) {
    final recordVM = context.watch<RecordViewModel>();
    final catVM = context.watch<SpendingCategoryViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          title: Text(
            DateFormat('yyyy년 M월 d일').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ) ??
                TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          centerTitle: true,
        ),
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
                    onChanged: (v) => setState(() {
                      _isSpending = v == '소비';
                      if (!_isSpending) _noSpendingChecked = false;
                    }),
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
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              checkboxTheme: CheckboxThemeData(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            child: Checkbox(
                              value: _noSpendingChecked,
                              onChanged: (v) => setState(
                                    () => _noSpendingChecked = v ?? false,
                              ),
                              materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(
                                () => _noSpendingChecked = !_noSpendingChecked,
                          ),
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
                        ? _buildSpendingContent(recordVM)
                        : _buildIncomeContent(),
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

                  // ✅ 선택: 로딩 표시(원하면 제거 가능)
                  if (catVM.loading)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          child: const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpacing.fieldSpacing),
                    ParagraphText(text: _isSpending ? '총 소비 금액' : '총 수입 금액'),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    _isSpending
                        ? Selector<RecordViewModel, String>(
                      selector: (_, vm) => vm.formattedTotal,
                      builder: (_, formattedTotal, __) {
                        return ParagraphText(
                          text: '$formattedTotal원',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        );
                      },
                    )
                        : ParagraphText(
                      text: '$_formattedIncomeTotal원',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.fieldSpacing),
                  ],
                ),
              ),
            ),

            CustomButton(
              text: '다음 단계',
              enabled: _isSpending
                  ? (_noSpendingChecked ||
                  recordVM.spendingEntries.any(
                        (e) => ((e['amount'] as num?) ?? 0) > 0,
                  ))
                  : true,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/record_diary',
                  arguments: _selectedDate,
                );
              },
            ),

            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingContent(RecordViewModel recordVM) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...recordVM.spendingEntries.map((entry) {
            return SpendingInputEntry(
              entry: entry,
              onDelete: () => recordVM.removeEntryByRef(entry),
            );
          }).toList(),
          const SizedBox(height: 12),
          SmallRoundedButton(
            text: '추가',
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : AppColors.greyBackground,
            textColor: Theme.of(context).colorScheme.onSurface,
            onPressed: () => recordVM.addEntry(),
          ),
          const SizedBox(height: AppSpacing.bottomSpacing),
        ],
      ),
    );
  }

  Widget _buildIncomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._incomeEntries.map((entry) {
            return SpendingInputEntry(
              entry: entry,
              onDelete: () => _removeIncomeEntry(entry),
            );
          }).toList(),
          const SizedBox(height: 12),
          Center(
            child: SmallRoundedButton(
              text: '추가',
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : AppColors.greyBackground,
              textColor: Theme.of(context).colorScheme.onSurface,
              onPressed: _addIncomeEntry,
            ),
          ),
          const SizedBox(height: AppSpacing.bottomSpacing),
        ],
      ),
    );
  }
}
