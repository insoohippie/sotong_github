import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sotong_local/component/texts/paragraph_text.dart';
import '../../../component/appbars/custom_app_bar_home.dart';
import '../../../component/buttons/small_rounded_button.dart';
import '../../../component/chart/semi_gauge_chart.dart';
import '../../../component/containers/rounded_info_container.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';

import '../../../view_model/communication/communication_view_model.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../pages/home/home_widgets/plan_name_edit_widget.dart';

class HomeWidgetTestPage extends StatefulWidget {
  const HomeWidgetTestPage({super.key});

  @override
  State<HomeWidgetTestPage> createState() => _HomeWidgetTestPageState();
}

class _HomeWidgetTestPageState extends State<HomeWidgetTestPage> {
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

  /// CommunicationViewModel에서 오늘 지출 금액 가져오기 (텍스트용)
  String _getSpendingForDate(DateTime date) {
    final comm = context.read<CommunicationViewModel>();
    final amount = 0; // double
    return '${amount.toStringAsFixed(0)}원';
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  /// D-Day 텍스트 생성
  String _buildDDayText(HomeViewModel vm) {
    final remain = vm.liveRemaining;
    if (remain == null) return '목표일 없음';
    if (remain.isNegative) return 'D-Day 달성';
    return 'D-${remain.inDays}';
  }

  /// D-Day 클릭 시 예쁜 카운트다운 다이얼로그
  void _showCountdownDialog(HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1초마다 다시 그리기 (vm.secondTick 사용)
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
                      '$days일 ${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                '1초씩 ${vm.perSecondSaving}원이 증가해요',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
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

  /// 실제 사용 금액(숫자) 가져오기
  double _getActualSpentAmount(DateTime date) {
    final comm = context.read<CommunicationViewModel>();
    return 100;
  }

  /// "7,000원" -> 7000
  double _parseAmount(String amountStr) {
    final cleaned = amountStr.replaceAll(RegExp(r'[원,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final comm = context.watch<CommunicationViewModel>();
    //
    // final _ = comm.firstEntryFor(_selectedDate);

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

    // 뷰모델 값
    final userName = vm.name;
    final planName = vm.planTitle;
    final savingPerSec = vm.perSecondSaving;
    final currentRate = vm.progressRatio;
    final fixedSpending = vm.dailyLimitText;

    // 날짜/지출
    final displayDate = _formatDate(_selectedDate);
    final todaySpending = _getSpendingForDate(_selectedDate);
    final bool hasSpendingRecord = todaySpending != '0원';

    // 한도/초과 여부
    final actualSpent = _getActualSpentAmount(_selectedDate);
    final dailyLimitAmount = _parseAmount(fixedSpending);
    final bool isOverLimit =
        hasSpendingRecord && dailyLimitAmount > 0 && actualSpent > dailyLimitAmount;

    final containerBackgroundColor = !hasSpendingRecord
        ? Colors.grey[200]!
        : isOverLimit
        ? const Color(0xFFFFEFEF)
        : const Color(0xFFEFF5FF);

    final actualSpentTextColor = !hasSpendingRecord
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// 1. 플랜 + D-Day + 모인 금액 + 반원 그래프
                      RoundedInfoContainer(
                        backgroundColor: const Color(0xFFF5F5F5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                        BorderRadius.circular(20),
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
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showCountdownDialog(vm),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: ParagraphText(
                                        text: _buildDDayText(vm),
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.fieldSpacing),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 원형 차트와 중앙 텍스트
                                SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // 바깥쪽 원형 차트 (전체 기간 배경)
                                      CustomPaint(
                                        size: const Size(300, 300),
                                        painter: SemiGaugePainter(
                                          progress: 1.0,
                                          backgroundColor: const Color(0xFFF1F1F1),
                                          progressColorStart: const Color(0xFFF1F1F1),
                                          progressColorEnd: const Color(0xFFF1F1F1),
                                          strokeWidth: 22,
                                          isFullCircle: true,
                                        ),
                                      ),
                                      // 안쪽 원형 차트 (실제 진행률)
                                      CustomPaint(
                                        size: const Size(300, 300),
                                        painter: SemiGaugePainter(
                                          progress: currentRate.clamp(0.0, 1.0),
                                          backgroundColor: Colors.transparent,
                                          progressColorStart: const Color(0xFF3C7BFF),
                                          progressColorEnd: const Color(0xFF3C7BFF),
                                          strokeWidth: 18,
                                          isFullCircle: true,
                                          innerProgress: currentRate.clamp(0.0, 1.0),
                                          innerBackgroundColor: Colors.transparent,
                                          innerProgressColorStart: const Color(0xFFB9D2FF),
                                          innerProgressColorEnd: const Color(0xFFB9D2FF),
                                          innerStrokeWidth: 15,
                                          innerRadiusRatio: 0.7,
                                        ),
                                      ),
                                      // 중앙 텍스트
                                      ValueListenableBuilder<int>(
                                        valueListenable: vm.secondTick,
                                        builder: (_, __, ___) {
                                          final remain = vm.liveRemaining;
                                          String dDayText = '목표일 없음';
                                          if (remain != null) {
                                            if (remain.isNegative) {
                                              dDayText = 'D-Day 달성';
                                            } else {
                                              dDayText = 'D-${remain.inDays}';
                                            }
                                          }
                                          
                                          return Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                dDayText,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                '모인 금액',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                vm.liveSavedAmountText,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3C7BFF),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 범례
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFB9D2FF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '진행한 기간',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF3C7BFF),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          '목표 달성까지',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // ⬇️ 여기 있던 '1초씩 ~원 증가' 문구는 다이얼로그 안으로 옮겼으므로 제거
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.fieldSpacing),

                      /// 2. 오늘 소비 / 한도 + 색상 변화
                      RoundedInfoContainer(
                        backgroundColor: containerBackgroundColor,
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: hasSpendingRecord
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
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
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pushNamed('/add_income_edit');
                                        },
                                        borderRadius:
                                        BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius:
                                            BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius:
                                        BorderRadius.circular(100),
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
                                        borderRadius:
                                        BorderRadius.circular(100),
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
                                        child: Row(
                                          children: [
                                            Text(
                                              todaySpending,
                                              style: TextStyle(
                                                color: actualSpentTextColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              ' / ',
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
