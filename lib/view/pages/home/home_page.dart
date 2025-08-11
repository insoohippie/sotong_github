import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/theme/app_colors.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/progressionBars/saving_progress_bar.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/texts/subtext.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../view_model/auth/signup_view_model.dart';
import '../../../view_model/communication/communication_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _getSpendingForDate(DateTime date) {
    final communicationViewModel = context.read<CommunicationViewModel>();
    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      final entry = communicationViewModel.diaryEntries.firstWhere((entry) {
        final entryNormalized = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
        );
        return entryNormalized.isAtSameMomentAs(normalizedDate);
      });

      return '${entry.spendingAmount.toStringAsFixed(0)}원';
    } catch (e) {
      return '0원';
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final userName = vm.signUpInfo?.name ?? '사용자';

    final planName = '집 사자!';
    final goalSavingTime = '25일 : 09시 : 32분 : 16초';
    final currentSaving = '345,132';
    final savingPerSec = '0.11';
    final currentRate = 0.52;
    final baseRate = 0.50;
    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final fixedSpending = '7,000원';

    final bool hasSpendingRecord = todaySpending != '0원';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ✅ CustomAppBarHome 내부 수정 필요함 (IconButton 또는 InkWell로 구성되었는지 확인)
            CustomAppBarHome(
              text: '$userName 님',
              unreadCount: 3,
              onNotifications: () {
                Navigator.of(context).pushNamed('/notification');
              },
              onSettings: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/setting');
              },
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RoundedInfoContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.planTagBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ParagraphText(
                                text: '$planName',
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            ParagraphText(
                              text: '목표 금액까지\n',
                              fontWeight: FontWeight.bold,
                            ),
                            ParagraphText(
                              text: '$goalSavingTime',
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: AppSpacing.sectionSpacing2),
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  HeaderText(text: '$currentSaving원'),
                                  SubText(
                                    text: '1초씩 $savingPerSec원이 증가해요',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSpacing.sectionSpacing2),
                            BubbleSavingProgressBar(
                              currentRate: currentRate,
                              baseRate: baseRate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RoundedInfoContainer(
                        backgroundColor: AppColors.greyBackground,
                        child: Column(
                          crossAxisAlignment: hasSpendingRecord
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ParagraphText(
                                  text: displayDate,
                                  fontWeight: FontWeight.bold,
                                ),
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(100),
                                        onTap: () => _changeDate(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.chevron_left, size: 24),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(100),
                                        onTap: () => _changeDate(1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(Icons.chevron_right, size: 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!hasSpendingRecord) ...[
                                  SmallRoundedButton(
                                    text: "소비 기록하러 가기",
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).pushNamed('/record_spending');
                                    },
                                  ),
                                  SubText(
                                    text: "아직 소비를 기록하지 않았어요",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ] else ...[
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context, rootNavigator: true).pushNamed('/today_spending');
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: MultiColorText(
                                          baseStyle: AppTextStyles.paragraph,
                                          parts: [
                                            TextPart('$todaySpending ', AppColors.primary, bold: true),
                                            TextPart('/ $fixedSpending', AppColors.text, bold: true),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
