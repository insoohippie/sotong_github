import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/home/home_view_model.dart';
import 'home_widgets/home_saving_chart_widget.dart';
import 'home_widgets/home_saving_countdown_sheet.dart';
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
    });
  }

  // 소비 입력 컨테이너에서 날짜 관련 함수
  DateTime _selectedDate = DateTime.now(); // 오늘 날짜

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  Future<void> _changeDate(int days) async {
    final vm = context.read<HomeViewModel>();
    final planStart = vm.latestPlan?.startDate ?? vm.latestPlan?.creationDate;
    if (planStart != null) {
      final nextDate = _selectedDate.add(Duration(days: days));
      if (nextDate.isBefore(DateTime(planStart.year, planStart.month, planStart.day))) {
        return;
      }
      setState(() {
        _selectedDate = nextDate;
      });
    } else {
      setState(() {
        _selectedDate = _selectedDate.add(Duration(days: days));
      });
    }
    await vm.loadDailySummary(_selectedDate);
  }

  /// D-Day 표시
  String _buildDDayText(HomeViewModel vm) {
    final remain = vm.liveRemaining;
    if (remain == null) return '목표일 없음';
    if (remain.isNegative) return 'D-Day 달성';
    return 'D-${remain.inDays}';
  }

  double _toChartPercent(double ratio) {
    final percent = (ratio * 100).clamp(0.0, 100.0);
    return (percent * 100).round() / 100;
  }

  @override
  Widget build(BuildContext context) {
    // 뷰모델 받아오기
    final vm = context.watch<HomeViewModel>();

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

    // 뷰 모델 변수 받아오기
    final userName = vm.name;
    final planName = vm.planTitle;
    final currentRate = vm.progressRatio;
    final fixedSpending = vm.dailyLimitText;

    final displayDate = _formatDate(_selectedDate);
    final actualSpent = vm.todaySpending.toDouble();
    final todaySpending = '${vm.todaySpending}원';
    final dailyLimit =
        double.tryParse(fixedSpending.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    final hasRecord = actualSpent > 0;
    final isOverLimit = hasRecord && dailyLimit > 0 && actualSpent > dailyLimit;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final containerBackgroundColor = !hasRecord
        ? (isDark ? theme.colorScheme.surface : Colors.grey[200]!)
        : isOverLimit
        ? (isDark ? const Color(0xFF3D2020) : const Color(0xFFFFEFEF))
        : (isDark ? theme.colorScheme.surface : const Color(0xFFEFF5FF));

    final spentTextColor = !hasRecord
        ? theme.colorScheme.onSurface
        : isOverLimit
        ? const Color(0xFFFF5F5F)
        : AppColors.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBarHome(
              text: '$userName 님',
              unreadCount: 3,
              onNotifications: () =>
                  Navigator.pushNamed(context, '/notification'),
              onSettings: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/setting'),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    children: [
                      RoundedInfoContainer(
                        backgroundColor: theme.colorScheme.surface,
                        padding: 12,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
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
                                        text: planName,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async =>
                                      await showPlanNameEditSheet(context),
                                      child: const Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            HomeSavingChartWidget(
                              vm: vm,
                              userPercent: _toChartPercent(vm.userPercent),
                              planPercent: _toChartPercent(vm.planPercent),

                              onOpenCountdown: () => _openSavingSheet(vm),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// 오늘 지출 UI
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: hasRecord
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ParagraphText(
                                  text: displayDate,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _changeDate(-1),
                                      child: Icon(
                                        Icons.chevron_left,
                                        color:
                                        theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _changeDate(1),
                                      child: Icon(
                                        Icons.chevron_right,
                                        color:
                                        theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (!hasRecord)
                              SmallRoundedButton(
                                text: "수입/소비 기록하러 가기",
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    '/record',
                                    arguments: _selectedDate,
                                  );
                                },
                              )
                            else
                              InkWell(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    '/today_record',
                                    arguments: _selectedDate,
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      todaySpending,
                                      style: TextStyle(
                                        color: spentTextColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' / ',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      fixedSpending,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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

  void _openSavingSheet(HomeViewModel vm) {
    final userPercent = (vm.userPercent * 100).round();
    final planPercent = (vm.planPercent * 100).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: HomeSavingCountdownSheet(
            vm: vm,
            planPercent: planPercent,
            userPercent: userPercent,
          ),
        );
      },
    );
  }
}
