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

  String _formatDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  /// D-Day 표시
  String _buildDDayText(HomeViewModel vm) {
    final remain = vm.liveRemaining;
    if (remain == null) return '목표일 없음';
    if (remain.isNegative) return 'D-Day 달성';
    return 'D-${remain.inDays}';
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

    final selectedDate = vm.selectedDate;
    final displayDate = _formatDate(selectedDate);

    final todayIncome = vm.todayIncome;
    final todaySpending = vm.todaySpending;

    final hasIncome = todayIncome > 0;
    final hasSpending = todaySpending > 0;

    final todayIncomeText = vm.todayIncomeText;
    final todaySpendingText = vm.todaySpendingText;

    final dailyLimit =
        double.tryParse(fixedSpending.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    final actualSpent = todaySpending.toDouble();
    final isOverLimit = hasSpending && dailyLimit > 0 && actualSpent > dailyLimit;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerBackgroundColor = !hasSpending
        ? (isDark ? theme.colorScheme.surface : Colors.grey[200]!)
        : isOverLimit
        ? (isDark ? const Color(0xFF3D2020) : const Color(0xFFFFEFEF))
        : (isDark ? theme.colorScheme.surface : const Color(0xFFEFF5FF));

    final spentTextColor = !hasSpending
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
                              userPercent: (currentRate * 100).round(),
                              planPercent: 60,
                              onOpenCountdown: () => _openSavingSheet(vm),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      /// 수입/소비 요약 UI
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment:
                          hasSpending ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                /// 왼쪽 - 날짜
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ParagraphText(
                                      text: displayDate,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),

                                /// 가운데 - 수입 표시
                                Expanded(
                                  child: Center(
                                    child: hasIncome
                                        ? Text(
                                      '+${vm.todayIncomeText}', // "10,000원"
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    )
                                        : const SizedBox.shrink(),
                                  ),
                                ),

                                /// 오른쪽 - 날짜 이동
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => vm.changeDate(-1),
                                          child: Icon(
                                            Icons.chevron_left,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => vm.changeDate(1),
                                          child: Icon(
                                            Icons.chevron_right,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (!hasSpending)
                              SmallRoundedButton(
                                text: "수입/소비 기록하러 가기",
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    '/record',
                                    arguments: selectedDate,
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
                                    arguments: selectedDate,
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      todaySpendingText,
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
    final userPercent = (vm.progressRatio * 100).round();
    final planPercent = 60;

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

//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
//
// import 'package:sotong_local/component/texts/paragraph_text.dart';
// import '../../../component/appbars/custom_app_bar_home.dart';
// import '../../../component/buttons/small_rounded_button.dart';
// import '../../../component/containers/rounded_info_container.dart';
// import '../../../component/theme/app_colors.dart';
// import '../../../component/theme/app_spacing.dart';
//
// import '../../../view_model/home/home_view_model.dart';
// import 'home_widgets/home_saving_chart_widget.dart';
// import 'home_widgets/home_saving_countdown_sheet.dart';
// import 'home_widgets/plan_name_edit_widget.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       context.read<HomeViewModel>().load();
//     });
//   }
//
//   // 소비 입력 컨테이너에서 날짜 관련 함수
//   DateTime _selectedDate = DateTime.now(); // 오늘 날짜
//
//   String _formatDate(DateTime date) {
//     const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
//     final weekday = weekdays[date.weekday - 1];
//     return '${date.month}월 ${date.day}일 ($weekday)';
//   }
//
//   void _changeDate(int days) {
//     setState(() {
//       _selectedDate = _selectedDate.add(Duration(days: days));
//     });
//     context.read<HomeViewModel>().loadDailySpending(_selectedDate);
//   }
//
//   /// 선택일이 오늘(날짜만)인지
//   bool _isSelectedDateToday() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final sel = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//     );
//     return sel == today;
//   }
//
//   /// 선택일(시간 제외)이 오늘 이전이면 +1일(미래 방향) 이동 가능. 오늘·미래면 `>` 비활성화.
//   bool _canGoForwardOneDay() {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final sel = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//     );
//     return sel.isBefore(today);
//   }
//
//   /// 플랜 시작일 당일 이전(과거)으로는 `<` 비활성화. 플랜 없거나 시작일 없으면 제한 없음.
//   bool _canGoBackwardOneDay(HomeViewModel vm) {
//     final raw = vm.latestPlan?.startDate;
//     if (raw == null) return true;
//     final planStart = DateTime(raw.year, raw.month, raw.day);
//     final sel = DateTime(
//       _selectedDate.year,
//       _selectedDate.month,
//       _selectedDate.day,
//     );
//     return sel.isAfter(planStart);
//   }
//
//   /// D-Day 표시
//   String _buildDDayText(HomeViewModel vm) {
//     final remain = vm.liveRemaining;
//     if (remain == null) return '목표일 없음';
//     if (remain.isNegative) return 'D-Day 달성';
//     return 'D-${remain.inDays}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // 뷰모델 받아오기
//     final vm = context.watch<HomeViewModel>();
//
//     if (vm.isLoading) {
//       return const Scaffold(
//         body: SafeArea(child: Center(child: CircularProgressIndicator())),
//       );
//     }
//     if (vm.error != null) {
//       return Scaffold(
//         body: SafeArea(child: Center(child: Text('오류: ${vm.error}'))),
//       );
//     }
//
//     // 뷰 모델 변수 받아오기
//     final userName = vm.name;
//     final planName = vm.planTitle;
//     final currentRate = vm.progressRatio;
//     final fixedSpending = vm.dailyLimitText;
//
//     final displayDate = _formatDate(_selectedDate);
//     final actualSpent = vm.todaySpending.toDouble();
//     final todaySpending = '${vm.todaySpending}원';
//     final dailyLimit =
//         double.tryParse(fixedSpending.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
//
//     final hasRecord = actualSpent > 0;
//     final isOverLimit = hasRecord && dailyLimit > 0 && actualSpent > dailyLimit;
//
//     /// 오늘이 아닌 날에 지출 기록이 없을 때 — 회색 카드 + 일일한도/일일한도 표시
//     final isPastDayNoRecord = !hasRecord && !_isSelectedDateToday();
//
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final containerBackgroundColor = isPastDayNoRecord
//         ? (isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey[300]!)
//         : !hasRecord
//         ? (isDark ? theme.colorScheme.surface : Colors.grey[200]!)
//         : isOverLimit
//         ? (isDark ? const Color(0xFF3D2020) : const Color(0xFFFFEFEF))
//         : (isDark ? theme.colorScheme.surface : const Color(0xFFEFF5FF));
//
//     final spentTextColor = !hasRecord
//         ? theme.colorScheme.onSurface
//         : isOverLimit
//         ? const Color(0xFFFF5F5F)
//         : AppColors.primary;
//
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             CustomAppBarHome(
//               text: '$userName 님',
//               unreadCount: 3,
//               onNotifications: () =>
//                   Navigator.pushNamed(context, '/notification'),
//               onSettings: () => Navigator.of(
//                 context,
//                 rootNavigator: true,
//               ).pushNamed('/setting'),
//             ),
//
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppSpacing.screenPadding,
//                   ),
//                   child: Column(
//                     children: [
//                       RoundedInfoContainer(
//                         backgroundColor: theme.colorScheme.surface,
//                         padding: 12,
//                         child: Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 12,
//                                         vertical: 4,
//                                       ),
//                                       decoration: BoxDecoration(
//                                         color: AppColors.planTagBackground,
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       child: ParagraphText(
//                                         text: planName,
//                                         color: AppColors.primary,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     InkWell(
//                                       onTap: () async =>
//                                       await showPlanNameEditSheet(context),
//                                       child: const Icon(
//                                         Icons.edit,
//                                         size: 20,
//                                         color: AppColors.primary,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//
//                             const SizedBox(height: 24),
//
//                             HomeSavingChartWidget(
//                               vm: vm,
//
//                               // userPercent: 실제 진행률(지금 HomePage에서 쓰던 currentRate 기반)
//                               userPercent: (currentRate * 100).round(),
//
//                               // planPercent: 일단 임시값(나중에 목표 페이스로 교체)
//                               planPercent: 60,
//
//                               onOpenCountdown: () => _openSavingSheet(vm),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 40),
//
//                       /// 오늘 지출 UI
//                       RoundedInfoContainer(
//                         backgroundColor: containerBackgroundColor,
//                         padding: 20,
//                         child: Column(
//                           crossAxisAlignment: (hasRecord || isPastDayNoRecord)
//                               ? CrossAxisAlignment.start
//                               : CrossAxisAlignment.center,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       padding: EdgeInsets.zero,
//                                       visualDensity: VisualDensity.compact,
//                                       constraints: const BoxConstraints(
//                                         minWidth: 36,
//                                         minHeight: 40,
//                                       ),
//                                       style: IconButton.styleFrom(
//                                         foregroundColor: theme
//                                             .colorScheme.onSurfaceVariant,
//                                         disabledForegroundColor: theme
//                                             .colorScheme.onSurfaceVariant
//                                             .withValues(alpha: 0.35),
//                                         tapTargetSize:
//                                         MaterialTapTargetSize.shrinkWrap,
//                                       ),
//                                       onPressed: _canGoBackwardOneDay(vm)
//                                           ? () => _changeDate(-1)
//                                           : null,
//                                       icon: const Icon(Icons.chevron_left),
//                                     ),
//                                     Padding(
//                                       padding: const EdgeInsets.symmetric(
//                                         horizontal: 2,
//                                       ),
//                                       child: ParagraphText(
//                                         text: displayDate,
//                                         fontSize: 20,
//                                         fontWeight: FontWeight.bold,
//                                         color: theme.colorScheme.onSurface,
//                                       ),
//                                     ),
//                                     IconButton(
//                                       padding: EdgeInsets.zero,
//                                       visualDensity: VisualDensity.compact,
//                                       constraints: const BoxConstraints(
//                                         minWidth: 36,
//                                         minHeight: 40,
//                                       ),
//                                       style: IconButton.styleFrom(
//                                         foregroundColor: theme
//                                             .colorScheme.onSurfaceVariant,
//                                         disabledForegroundColor: theme
//                                             .colorScheme.onSurfaceVariant
//                                             .withValues(alpha: 0.35),
//                                         tapTargetSize:
//                                         MaterialTapTargetSize.shrinkWrap,
//                                       ),
//                                       onPressed: _canGoForwardOneDay()
//                                           ? () => _changeDate(1)
//                                           : null,
//                                       icon: const Icon(Icons.chevron_right),
//                                     ),
//                                   ],
//                                 ),
//                                 Stack(
//                                   clipBehavior: Clip.none,
//                                   children: [
//                                     IconButton(
//                                       padding: EdgeInsets.zero,
//                                       visualDensity: VisualDensity.compact,
//                                       constraints: const BoxConstraints(
//                                         minWidth: 40,
//                                         minHeight: 40,
//                                       ),
//                                       tooltip: '기록·미기록 캘린더',
//                                       style: IconButton.styleFrom(
//                                         foregroundColor: AppColors.primary,
//                                         tapTargetSize:
//                                         MaterialTapTargetSize.shrinkWrap,
//                                       ),
//                                       onPressed: () {
//                                         HapticFeedback.selectionClick();
//                                         Navigator.of(
//                                           context,
//                                           rootNavigator: true,
//                                         ).pushNamed(
//                                           '/pending_spending_intro',
//                                           arguments: <String, dynamic>{
//                                             'initialMonth': _selectedDate,
//                                           },
//                                         );
//                                       },
//                                       icon: const Icon(
//                                         Icons.calendar_month_outlined,
//                                       ),
//                                     ),
//                                     Positioned(
//                                       // 아이콘 밖으로 밀어 캘린더를 덮지 않게 (끝 모서리 쪽)
//                                       right: -3.5,
//                                       top: -3.5,
//                                       child: IgnorePointer(
//                                         child: Container(
//                                           width: 14,
//                                           height: 14,
//                                           alignment: Alignment.center,
//                                           decoration: BoxDecoration(
//                                             color: Colors.red.shade600,
//                                             shape: BoxShape.circle,
//                                             border: Border.all(
//                                               color: theme.colorScheme.surface,
//                                               width: 1.5,
//                                             ),
//                                           ),
//                                           child: const Text(
//                                             '!',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 9,
//                                               fontWeight: FontWeight.w800,
//                                               height: 1,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),
//
//                             if (isPastDayNoRecord)
//                               InkWell(
//                                 onTap: () {
//                                   Navigator.of(
//                                     context,
//                                     rootNavigator: true,
//                                   ).pushNamed(
//                                     '/today_record',
//                                     arguments: _selectedDate,
//                                   );
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       fixedSpending,
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       ' / ',
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       fixedSpending,
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             else if (!hasRecord)
//                               SmallRoundedButton(
//                                 text: "수입/소비 기록하러 가기",
//                                 onPressed: () {
//                                   Navigator.of(
//                                     context,
//                                     rootNavigator: true,
//                                   ).pushNamed(
//                                     '/today_record',
//                                     arguments: _selectedDate,
//                                   );
//                                 },
//                               )
//                             else
//                               InkWell(
//                                 onTap: () {
//                                   Navigator.of(
//                                     context,
//                                     rootNavigator: true,
//                                   ).pushNamed(
//                                     '/today_record',
//                                     arguments: _selectedDate,
//                                   );
//                                 },
//                                 child: Row(
//                                   children: [
//                                     Text(
//                                       todaySpending,
//                                       style: TextStyle(
//                                         color: spentTextColor,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       ' / ',
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     Text(
//                                       fixedSpending,
//                                       style: TextStyle(
//                                         color: theme.colorScheme.onSurface,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _openSavingSheet(HomeViewModel vm) {
//     final userPercent = (vm.progressRatio * 100).round();
//
//     // planPercent는 지금 당장은 임시값으로 시작(나중에 목표 페이스로 바꾸면 됨)
//     final planPercent = 60;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       useSafeArea: true,
//       backgroundColor: Colors.transparent,
//       barrierColor: Colors.black54,
//       builder: (_) {
//         return FractionallySizedBox(
//           heightFactor: 0.7,
//           child: HomeSavingCountdownSheet(
//             vm: vm,
//             planPercent: planPercent,
//             userPercent: userPercent,
//           ),
//         );
//       },
//     );
//   }
// }
