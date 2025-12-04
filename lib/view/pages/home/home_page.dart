import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/chart/half_donut_chart.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/communication/communication_view_model.dart';
import '../../../view_model/home/home_view_model.dart';
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

  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _getSpendingForDate(DateTime date) {
    final home = context.read<HomeViewModel>();
    return '${home.todaySpending}원';
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    context.read<HomeViewModel>().loadDailySpending(_selectedDate);
  }

  /// D-Day 표시
  String _buildDDayText(HomeViewModel vm) {
    final remain = vm.liveRemaining;
    if (remain == null) return '목표일 없음';
    if (remain.isNegative) return 'D-Day 달성';
    return 'D-${remain.inDays}';
  }

  /// D-Day 카운트다운 상세 보기
  void _showCountdownDialog(HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: vm.secondTick,
                builder: (_, __, ___) {
                  final remain = vm.liveRemaining ?? Duration.zero;
                  final clamped =
                  remain.isNegative ? Duration.zero : remain;

                  final days = clamped.inDays;
                  final hours = clamped.inHours % 24;
                  final minutes = clamped.inMinutes % 60;
                  final seconds = clamped.inSeconds % 60;

                  String twoDigits(int v) => v.toString().padLeft(2, '0');

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      '$days일 ${twoDigits(hours)}:'
                          '${twoDigits(minutes)}:${twoDigits(seconds)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                '1초마다 ${vm.perSecondSaving}원이 증가해요',
                style:
                const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final userName = vm.name;
    final planName = vm.planTitle;
    final currentRate = vm.progressRatio;
    final fixedSpending = vm.dailyLimitText;

    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final actualSpent = vm.todaySpending.toDouble();
    final dailyLimit = double.tryParse(
      fixedSpending.replaceAll(RegExp(r'[^0-9]'), ''),
    ) ?? 0.0;

    final hasRecord = actualSpent > 0;
    final isOverLimit = hasRecord && dailyLimit > 0 && actualSpent > dailyLimit;

    final containerBackgroundColor = !hasRecord
        ? Colors.grey[200]!
        : isOverLimit
        ? const Color(0xFFFFEFEF)
        : const Color(0xFFEFF5FF);

    final spentTextColor = !hasRecord
        ? AppColors.text
        : isOverLimit
        ? const Color(0xFFFF5F5F)
        : const Color(0xFF0062FF);

    return Scaffold(
      backgroundColor: Colors.white,
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      /// 🔹 플랜 정보 + 목표 진행률
                      RoundedInfoContainer(
                        backgroundColor: const Color(0xFFF5F5F5),
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
                                InkWell(
                                  onTap: () => _showCountdownDialog(vm),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ParagraphText(
                                      text: _buildDDayText(vm),
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const ParagraphText(
                                  text: '모인 금액',
                                  fontWeight: FontWeight.bold,
                                ),
                                const SizedBox(height: 6),
                                ValueListenableBuilder<int>(
                                  valueListenable: vm.secondTick,
                                  builder: (_, __, ___) {
                                    return Text(
                                      vm.liveSavedAmountText,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: HalfDonutChart(
                                    outerProgress: 100,
                                    innerProgress:
                                    (currentRate * 100).round(),
                                    state: true,
                                    width: 300,
                                    height: 180,
                                    showLegend: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// 🔹 오늘 지출 UI
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment:
                          hasRecord ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    ParagraphText(
                                      text: displayDate,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () =>
                                          Navigator.of(context, rootNavigator: true)
                                              .pushNamed('/add_income_edit'),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(Icons.add,
                                            size: 18,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _changeDate(-1),
                                      child: const Icon(Icons.chevron_left),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _changeDate(1),
                                      child: const Icon(Icons.chevron_right),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (!hasRecord)
                              SmallRoundedButton(
                                text: "소비 기록하러 가기",
                                onPressed: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/record_spending');
                                },
                              )
                            else
                              InkWell(
                                onTap: () {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamed('/today_spending');
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
                                    const Text(' / ',
                                        style: TextStyle(
                                            color: AppColors.text,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      fixedSpending,
                                      style: const TextStyle(
                                        color: AppColors.text,
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
}
