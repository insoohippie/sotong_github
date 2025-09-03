import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/progressionBars/saving_progress_bar.dart';
import '../../../component/texts/multi_color_text.dart';
import '../../../component/texts/subtext.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../component/theme/app_text_styles.dart';
import '../../../view_model/communication/communication_view_model.dart';
import '../../../view_model/home/home_viewmodel.dart';
import '../../../view_model/services/saving_calculator.dart';
import 'home_widgets/plan_name_edit_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HomeViewModel>().load();
      context.read<CommunicationViewModel>().loadMonth(DateTime.now());
    });
  }

  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _getSpendingForDate(DateTime date) {
    final comm = context.read<CommunicationViewModel>();
    final amount = comm.spendingFor(date);
    return '${amount.toStringAsFixed(0)}원';
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    final comm = context.watch<CommunicationViewModel>();
    final entry = comm.firstEntryFor(_selectedDate);

    // 로딩/에러 처리
    if (vm.isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (vm.error != null) {
      return Scaffold(
        body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))),
      );
    }

    final userName = vm.name;                                    // ✔ 사용자명
    final planName = vm.planTitle;                               // ✔ 플랜명
    final savingPerSec = vm.perSecondSaving;                     // ✔ 1초당 저축
    final currentRate = vm.progressRatio;                        // ✔ 진행율(저축비중)
    final baseRate = 0.50;                                       // 수정 필요
    final fixedSpending = vm.dailyLimitText;                     // ✔ 하루 소비한도

    // (오늘 지출 동작은 기존 CommunicationViewModel 로직 유지)
    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final bool hasSpendingRecord = todaySpending != '0원';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바 (예시)
            CustomAppBarHome(
              text: '${vm.name} 님',
              unreadCount: 3,
              onNotifications: () => Navigator.pushNamed(context, '/notification'),
              onSettings: () => Navigator.of(context, rootNavigator: true).pushNamed('/setting'),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      RoundedInfoContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
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
                                const SizedBox(width: 8),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      await showPlanNameEditSheet(context);
                                    },
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),
                            // 목표까지 남은 시간 (1초마다 갱신)
                            ParagraphText(text: '목표 금액까지', fontWeight: FontWeight.bold),
                            ValueListenableBuilder<int>(
                              valueListenable: vm.secondTick,
                              builder: (_, __, ___) => ParagraphText(
                                text: vm.liveCountdownText,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sectionSpacing2),
                            Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ValueListenableBuilder<int>(
                                    valueListenable: vm.secondTick,
                                    builder: (_, __, ___) => HeaderText(
                                      text: vm.liveSavedAmountText, // 예: "345,132원"
                                    ),
                                  ),
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
                      const SizedBox(height: AppSpacing.fieldSpacing),
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
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(-1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_left,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        onTap: () => _changeDate(1),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 24,
                                          ),
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
                                      Navigator.of(
                                        context,
                                        rootNavigator: true,
                                      ).pushNamed('/record_spending');
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
                                        Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).pushNamed('/today_spending');
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: MultiColorText(
                                          baseStyle: AppTextStyles.paragraph,
                                          parts: [
                                            TextPart(
                                              '$todaySpending ',
                                              AppColors.primary,
                                              bold: true,
                                            ),
                                            TextPart(
                                              '/ $fixedSpending',
                                              AppColors.text,
                                              bold: true,
                                            ),
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
