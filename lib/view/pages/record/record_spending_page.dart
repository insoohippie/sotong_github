import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/custom_app_bar_title_subtitle.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/period_toggle.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../view_model/record/record_view_model.dart';
import 'record_widgets/spending_input_entry.dart';

class RecordSpendingPage extends StatefulWidget {
  const RecordSpendingPage({super.key});

  @override
  State<RecordSpendingPage> createState() => _RecordSpendingPageState();
}

class _RecordSpendingPageState extends State<RecordSpendingPage> {
  /// true: 소비, false: 수입
  bool _isSpending = true;

  /// 수입 토글용 항목 (소비와 동일한 SpendingInputEntry + isIncome)
  final List<Map<String, dynamic>> _incomeEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordViewModel>().resetSpending();
    });
    _addIncomeEntry();
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
    final args = ModalRoute.of(context)?.settings.arguments;
    final DateTime selectedDate = (args is DateTime) ? args : DateTime.now();

    final viewModel = context.watch<RecordViewModel>();

    final String formattedDate =
        '${selectedDate.year}년 ${selectedDate.month}월 ${selectedDate.day}일';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarTitleSubtitle(
              title: '소비 기록하기',
              subtitle: formattedDate,
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 12),
            TwoOptionToggle(
              labels: const ['수입', '소비'],
              selected: _isSpending ? '소비' : '수입',
              onChanged: (v) => setState(() => _isSpending = v == '소비'),
              width: 120,
              height: 34,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: _isSpending
                    ? _buildSpendingContent(viewModel)
                    : _buildIncomeContent(),
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
              enabled: true,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/record_diary',
                  arguments: selectedDate,
                );
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingContent(RecordViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ...viewModel.spendingEntries.map((entry) {
            return SpendingInputEntry(
              entry: entry,
              categoryItems: ['식비', '교통비', '문화비'],
              onDelete: () => viewModel.removeEntryByRef(entry),
            );
          }).toList(),
          const SizedBox(height: 12),
          SmallRoundedButton(
            text: '추가',
            backgroundColor: AppColors.greyBackground,
            textColor: AppColors.text,
            onPressed: () => viewModel.addEntry(),
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
              categoryItems: const [],
              onDelete: () => _removeIncomeEntry(entry),
              // isIncome: true,
              // onEntryChanged: () => setState(() {}),
            );
          }).toList(),
          const SizedBox(height: 12),
          Center(
            child: SmallRoundedButton(
              text: '추가',
              backgroundColor: AppColors.greyBackground,
              textColor: AppColors.text,
              onPressed: _addIncomeEntry,
            ),
          ),
          const SizedBox(height: AppSpacing.bottomSpacing),
        ],
      ),
    );
  }
}
