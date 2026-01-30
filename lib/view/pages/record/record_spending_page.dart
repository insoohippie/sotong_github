import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../component/appbars/custom_app_bar_title_subtitle.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/texts/paragraph_text.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/record/record_view_model.dart';
import '../../../view_model/category/category_edit_view_model.dart'; // ✅ 추가

import 'record_widgets/spending_input_entry.dart';

class RecordSpendingPage extends StatefulWidget {
  const RecordSpendingPage({super.key});

  @override
  State<RecordSpendingPage> createState() => _RecordSpendingPageState();
}

class _RecordSpendingPageState extends State<RecordSpendingPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1) 소비 입력 초기화
      context.read<RecordViewModel>().resetSpending();

      // 2) ✅ 카테고리 VM도 선택 날짜 기준으로 로드
      final args = ModalRoute.of(context)?.settings.arguments;
      final DateTime selectedDate = (args is DateTime) ? args : DateTime.now();
      await context.read<CategoryEditViewModel>().setSelectedDate(selectedDate);
      // setSelectedDate 내부에서 loadForSelectedDate() 호출됨
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final DateTime selectedDate = (args is DateTime) ? args : DateTime.now();

    final viewModel = context.watch<RecordViewModel>();

    final formattedDate =
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ...viewModel.spendingEntries.map((entry) {
                        return SpendingInputEntry(
                          entry: entry,
                          categoryItems: const [], // (호환성 유지용)
                          onDelete: () => viewModel.removeEntryByRef(entry),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      SmallRoundedButton(
                        text: '추가',
                        backgroundColor: AppColors.greyBackground,
                        textColor: AppColors.text,
                        onPressed: () {
                          viewModel.addEntry();
                        },
                      ),
                      const SizedBox(height: AppSpacing.bottomSpacing),
                    ],
                  ),
                ),
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
                    const ParagraphText(text: '총 소비 금액'),
                    const SizedBox(height: AppSpacing.itemSpacing),
                    Selector<RecordViewModel, String>(
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
}
