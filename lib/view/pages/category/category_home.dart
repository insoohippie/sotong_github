import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/appbars/custom_app_bar_title_subtitle.dart';
import 'package:sotong_local/component/buttons/custom_button.dart';
import 'package:sotong_local/component/buttons/small_rounded_button.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/component/theme/app_spacing.dart';
import 'package:sotong_local/view_model/record/record_view_model.dart';
import '../record/record_widgets/spending_input_entry.dart';
import 'category_state_manager.dart';

/// 카테고리 홈 페이지 - 소비기록 메인 화면
class CategoryHomePage extends StatefulWidget {
  const CategoryHomePage({Key? key}) : super(key: key);

  @override
  State<CategoryHomePage> createState() => _CategoryHomePageState();
}

class _CategoryHomePageState extends State<CategoryHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordViewModel>().resetSpending();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecordViewModel>();
    final date = '2025년 7월 24일';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarTitleSubtitle(
              title: '소비 기록하기',
              subtitle: date,
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
                          categoryItems:
                              CategoryStateManager.getActiveDailyExpenseCategories(),
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
                Navigator.pushNamed(context, '/record_diary');
              },
            ),
            const SizedBox(height: AppSpacing.bottomSpacing),
          ],
        ),
      ),
    );
  }
}
