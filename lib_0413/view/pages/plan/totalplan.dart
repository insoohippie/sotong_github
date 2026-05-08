import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:sotong_local/view/pages/plan/plan_widgets/plan_celebration/sequential_chart_widget.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../model/plan/total_plan.dart';
import '../../../model/record/record_entry.dart';
import '../../../view_model/communication/communication_view_model.dart';
import '../communication/comm_widgets/date_detail_modal.dart';
import '../../../model/plan/plan_metrics.dart';
import '../../../model/plan/sub_plan.dart';
import '../../../model/record/day_record.dart';
import '../../../model/setting/past_plan_snapshot.dart';
import 'celebration_plan_success.dart';

/// ===========================================================================
/// 플랜 종합 대시보드 페이지
/// - 플랜 정보 요약 (목표 금액, 현재 금액, 진행률, 예상 완료일)
/// - 감정 기록 통계 (감정 분포, 최근 감정)
/// - 소비 기록 통계 (월별 소비, 카테고리별 소비)
/// - 일지 기록 (최근 일지)
/// - 인사이트/분석
/// ===========================================================================
class TotalPlanPage extends StatefulWidget {
  const TotalPlanPage({super.key});

  @override
  State<TotalPlanPage> createState() => _TotalPlanPageState();
}

class _TotalPlanPageState extends State<TotalPlanPage>
    with TickerProviderStateMixin {
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');
  final PageController _pageController = PageController();
  // 감정 포디움 바 애니메이션 (3위, 2위, 1위 순서)
  late AnimationController _emotionBarThirdController;
  late AnimationController _emotionBarSecondController;
  late AnimationController _emotionBarFirstController;
  // 감정 아이템 애니메이션 (3위, 2위, 1위 순서)
  late AnimationController _emotionItemThirdController;
  late AnimationController _emotionItemSecondController;
  late AnimationController _emotionItemFirstController;
  // 카테고리 포디움 바 애니메이션 (3위, 2위, 1위 순서)
  late AnimationController _categoryBarThirdController;
  late AnimationController _categoryBarSecondController;
  late AnimationController _categoryBarFirstController;
  // 카테고리 아이템 애니메이션 (3위, 2위, 1위 순서)
  late AnimationController _categoryItemThirdController;
  late AnimationController _categoryItemSecondController;
  late AnimationController _categoryItemFirstController;
  // 나머지 리스트 애니메이션 (4위부터)
  late AnimationController _emotionListController;
  late AnimationController _categoryListController;
  Timer? _hapticTimer;

  // 하드코딩된 데이터
  late final TotalPlan _plan;
  late final Map<String, int> _emotionCounts;
  late final Map<String, double> _categorySpending;
  late final List<DayRecord> _recentDiaries;

  // 달력 상태
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _initializeHardcodedData();
    // 감정 포디움 바 애니메이션 컨트롤러 (밑에서 올라오기)
    _emotionBarThirdController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _emotionBarSecondController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _emotionBarFirstController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // 감정 아이템 애니메이션 컨트롤러 (페이드인 + 스케일)
    _emotionItemThirdController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _emotionItemSecondController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _emotionItemFirstController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // 카테고리 포디움 바 애니메이션 컨트롤러 (밑에서 올라오기)
    _categoryBarThirdController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _categoryBarSecondController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _categoryBarFirstController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // 카테고리 아이템 애니메이션 컨트롤러 (페이드인 + 스케일)
    _categoryItemThirdController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _categoryItemSecondController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _categoryItemFirstController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // 나머지 리스트 애니메이션 컨트롤러 (페이드인)
    _emotionListController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _categoryListController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    // 첫 프레임 이후 순차 애니메이션 시작 (3위 -> 2위 -> 1위)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            // 감정 포디움: 3위 -> 2위 -> 1위 (딜레이 0.6초)
            // 포디움 바 애니메이션
            _emotionBarThirdController.forward();
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _emotionBarSecondController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) _emotionBarFirstController.forward();
            });
            // 감정 아이템 애니메이션 (포디움 바 애니메이션 완료 후 시작)
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _emotionItemThirdController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) _emotionItemSecondController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (mounted) _emotionItemFirstController.forward();
            });
            // 감정 리스트 애니메이션 (포디움 완료 후 마지막에)
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted) _emotionListController.forward();
            });
            // 카테고리 포디움: 3위 -> 2위 -> 1위 (딜레이 0.6초)
            // 포디움 바 애니메이션
            _categoryBarThirdController.forward();
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _categoryBarSecondController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) _categoryBarFirstController.forward();
            });
            // 카테고리 아이템 애니메이션 (포디움 바 애니메이션 완료 후 시작)
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) _categoryItemThirdController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1200), () {
              if (mounted) _categoryItemSecondController.forward();
            });
            Future.delayed(const Duration(milliseconds: 1800), () {
              if (mounted) _categoryItemFirstController.forward();
            });
            // 카테고리 리스트 애니메이션 (포디움 완료 후 마지막에)
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted) _categoryListController.forward();
            });
          }
        });
      }
    });
  }

  /// 포디움 애니메이션(~2.3초)에 맞춰 쫘라락 햅틱 (12회, 150ms 간격)
  void _playPodiumSequentialHaptic() {
    _hapticTimer?.cancel();
    HapticFeedback.selectionClick();
    int count = 1;
    _hapticTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted || count >= 12) {
        _hapticTimer?.cancel();
        _hapticTimer = null;
        return;
      }
      HapticFeedback.selectionClick();
      count++;
    });
  }

  @override
  void dispose() {
    _hapticTimer?.cancel();
    _pageController.dispose();
    _emotionBarThirdController.dispose();
    _emotionBarSecondController.dispose();
    _emotionBarFirstController.dispose();
    _emotionItemThirdController.dispose();
    _emotionItemSecondController.dispose();
    _emotionItemFirstController.dispose();
    _categoryBarThirdController.dispose();
    _categoryBarSecondController.dispose();
    _categoryBarFirstController.dispose();
    _categoryItemThirdController.dispose();
    _categoryItemSecondController.dispose();
    _categoryItemFirstController.dispose();
    _emotionListController.dispose();
    _categoryListController.dispose();
    super.dispose();
  }

  void _initializeHardcodedData() {
    // 플랜 데이터
    final now = DateTime.now();
    final metrics = PlanMetrics.fromRange(
      startDate: now,
      endDate: now.add(const Duration(days: 29)),
      monthlyIncomeAmount: 3500000,
      monthlyConsumeAmount: 980000,
      dailyConsumeAmount: 20000,
    );

    _plan = TotalPlan(
      planId: 'demo_plan',
      planName: '세계여행 플랜',
      targetAmount: 10000000, // 1,000만원
      currentAmount: 3500000, // 350만원
      currentAsset: 2000000, // 200만원
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now.add(const Duration(days: 180)),
      modEndDate: null,
      creationDate: now.subtract(const Duration(days: 30)),
      autoService: true,
      subPlans: const {},
      result: TotalResult(
        totalMetrics: metrics,
        subResult: const SubPlanResult(subMetrics: [], subPlanList: []),
      ),
    );

    // 감정 통계 (JSON 파일에 맞게 수정)
    _emotionCounts = {'좋음': 15, '평온': 12, '슬픔': 5, '스트레스': 3, '동기부여': 2};

    // 카테고리별 소비
    _categorySpending = {
      '식비': 450000,
      '교통비': 120000,
      '카페': 80000,
      '쇼핑': 200000,
      '여가': 150000,
    };

    // 최근 일지
    _recentDiaries = [
      DayRecord(
        date: now.subtract(const Duration(days: 1)),
        totalSpendingAmount: 35000,
        totalIncomeAmount: 0,
        emotion: '좋음',
        comment: '오늘은 친구들과 맛있는 식사를 했다. 기분이 좋았다!',
        spendingEntries: [
          RecordEntry(
            id: '1',
            categoryKey: '식비',
            category: '식비',
            amount: 25000,
            note: '저녁 식사',
          ),
          RecordEntry(
            id: '2',
            categoryKey: '카페',
            category: '카페',
            amount: 10000,
            note: '커피',
          ),
        ],
        incomeEntries: const [],
      ),

      DayRecord(
        date: now.subtract(const Duration(days: 2)),
        totalSpendingAmount: 28000,
        totalIncomeAmount: 0,
        emotion: '평온',
        comment: '평범하지만 만족스러운 하루였다.',
        spendingEntries: [
          RecordEntry(
            id: '3',
            categoryKey: '식비',
            category: '식비',
            amount: 15000,
            note: '점심',
          ),
          RecordEntry(
            id: '4',
            categoryKey: '교통비',
            category: '교통비',
            amount: 13000,
            note: '지하철',
          ),
        ],
        incomeEntries: const [],
      ),

      DayRecord(
        date: now.subtract(const Duration(days: 3)),
        totalSpendingAmount: 45000,
        totalIncomeAmount: 0,
        emotion: '좋음',
        comment: '새로운 옷을 샀다. 스타일이 마음에 든다!',
        spendingEntries: [
          RecordEntry(
            id: '5',
            categoryKey: '쇼핑',
            category: '쇼핑',
            amount: 45000,
            note: '옷 구매',
          ),
        ],
        incomeEntries: const [],
      ),

      DayRecord(
        date: now.subtract(const Duration(days: 5)),
        totalSpendingAmount: 32000,
        totalIncomeAmount: 0,
        emotion: '슬픔',
        comment: '오늘은 조금 우울했다. 하지만 내일은 더 나아질 거야.',
        spendingEntries: [
          RecordEntry(
            id: '6',
            categoryKey: '식비',
            category: '식비',
            amount: 20000,
            note: '저녁',
          ),
          RecordEntry(
            id: '7',
            categoryKey: '여가',
            category: '여가',
            amount: 12000,
            note: '영화',
          ),
        ],
        incomeEntries: const [],
      ),

      DayRecord(
        date: now.subtract(const Duration(days: 7)),
        totalSpendingAmount: 25000,
        totalIncomeAmount: 0,
        emotion: '평온',
        comment: '집에서 푹 쉬는 하루였다.',
        spendingEntries: [
          RecordEntry(
            id: '8',
            categoryKey: '식비',
            category: '식비',
            amount: 25000,
            note: '배달음식',
          ),
        ],
        incomeEntries: const [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠 (플랜 정보)
            Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '나의 기록',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _plan.planName ?? '플랜 종합 대시보드',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                ),
                // 카드 슬라이드 영역
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      // 페이지가 변경될 때 애니메이션 재시작
                      if (index == 1) {
                        // 감정 기록 페이지 (2번 카드) - 3위 -> 2위 -> 1위 순서
                        _playPodiumSequentialHaptic();
                        // 포디움 바 애니메이션 리셋
                        _emotionBarThirdController.reset();
                        _emotionBarSecondController.reset();
                        _emotionBarFirstController.reset();
                        // 감정 아이템 애니메이션 리셋
                        _emotionItemThirdController.reset();
                        _emotionItemSecondController.reset();
                        _emotionItemFirstController.reset();
                        // 감정 리스트 애니메이션 리셋
                        _emotionListController.reset();
                        // 포디움 바 애니메이션 시작
                        _emotionBarThirdController.forward();
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) _emotionBarSecondController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) _emotionBarFirstController.forward();
                        });
                        // 감정 아이템 애니메이션 시작 (포디움 바 완료 후)
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) _emotionItemThirdController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) _emotionItemSecondController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1800), () {
                          if (mounted) _emotionItemFirstController.forward();
                        });
                        // 감정 리스트 애니메이션 시작 (포디움 완료 후 마지막에)
                        Future.delayed(const Duration(milliseconds: 2000), () {
                          if (mounted) _emotionListController.forward();
                        });
                      } else if (index == 2) {
                        // 소비 기록 페이지 (3번 카드) - 3위 -> 2위 -> 1위 순서
                        _playPodiumSequentialHaptic();
                        // 포디움 바 애니메이션 리셋
                        _categoryBarThirdController.reset();
                        _categoryBarSecondController.reset();
                        _categoryBarFirstController.reset();
                        // 카테고리 아이템 애니메이션 리셋
                        _categoryItemThirdController.reset();
                        _categoryItemSecondController.reset();
                        _categoryItemFirstController.reset();
                        // 카테고리 리스트 애니메이션 리셋
                        _categoryListController.reset();
                        // 포디움 바 애니메이션 시작
                        _categoryBarThirdController.forward();
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) _categoryBarSecondController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) _categoryBarFirstController.forward();
                        });
                        // 카테고리 아이템 애니메이션 시작 (포디움 바 완료 후)
                        Future.delayed(const Duration(milliseconds: 600), () {
                          if (mounted) _categoryItemThirdController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          if (mounted) _categoryItemSecondController.forward();
                        });
                        Future.delayed(const Duration(milliseconds: 1800), () {
                          if (mounted) _categoryItemFirstController.forward();
                        });
                        // 카테고리 리스트 애니메이션 시작 (포디움 완료 후 마지막에)
                        Future.delayed(const Duration(milliseconds: 2000), () {
                          if (mounted) _categoryListController.forward();
                        });
                      }
                    },
                    children: [
                      // 1번 카드: 플랜 요약
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: 16,
                        ),
                        child: _buildPlanSummaryCard(),
                      ),
                      // 2번 카드: 감정 기록 통계
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: 16,
                        ),
                        child: _buildEmotionStatsCard(),
                      ),
                      // 3번 카드: 소비 기록 통계
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: 16,
                        ),
                        child: _buildSpendingStatsCard(),
                      ),
                      // 4번 카드: 최근 일지 기록
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: 16,
                        ),
                        child: _buildRecentDiariesCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 하단 고정 네비게이션 바 (ChatBottomInputArea 스타일)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 고정 네비게이션 바
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.only(top: 30, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'PDF로 저장하기',
              onPressed: () {
                // PDF 저장 기능 구현
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                final snapshot = _createCurrentSnapshot();
                if (snapshot == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CelebrationPlanSuccessPage(
                      planName: _plan.planName,
                      daysTaken: snapshot.daysTaken,
                      snapshot: snapshot,
                    ),
                  ),
                );
              },
              child: Text(
                '플랜 완료하고 축하 보기',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 현재 4개 카드 기준으로 지난 플랜 스냅샷 생성 (celebration 저장용)
  PastPlanSnapshot? _createCurrentSnapshot() {
    final now = DateTime.now();
    final startDate = _plan.startDate ?? now;
    final endDate = _plan.endDate ?? now.add(const Duration(days: 180));
    final totalDays = endDate.difference(startDate).inDays;
    final daysElapsed = now.difference(startDate).inDays;
    final targetAmount = _plan.targetAmount ?? 0;
    final currentAmount = _plan.currentAmount + _plan.currentAsset;
    final progressRate = targetAmount > 0
        ? (currentAmount / targetAmount * 100).clamp(0.0, 100.0)
        : 0.0;
    final averagePace = daysElapsed > 0
        ? (progressRate / daysElapsed).toStringAsFixed(2)
        : '0.00';
    final averageDailySaving = daysElapsed > 0
        ? (currentAmount / daysElapsed).round()
        : 0;

    final restraintDays = (totalDays * 0.76).round();
    final restraintProgress = totalDays > 0
        ? (restraintDays / totalDays * 100).round()
        : 0;
    const targetProgress = 23;
    const savingProgress = 68;

    final diaries = _recentDiaries
        .map(
          (d) => {
        'date': d.date.toIso8601String(),
        'totalAmount': d.totalSpendingAmount,
        'emotion': d.emotion,
        'comment': d.comment,
      },
    )
        .toList();

    return PastPlanSnapshot(
      id: '${_plan.planId}_${now.millisecondsSinceEpoch}',
      planName: _plan.planName ?? '플랜',
      completedAt: now,
      daysTaken: totalDays,
      startDate: startDate,
      endDate: endDate,
      restraintProgress: restraintProgress.clamp(0, 100),
      targetProgress: targetProgress,
      savingProgress: savingProgress,
      emotionCounts: Map<String, int>.from(_emotionCounts),
      categorySpending: Map<String, double>.from(_categorySpending),
      diaries: diaries,
      averagePace: averagePace,
      averageDailySaving: averageDailySaving,
    );
  }

  // 공통 카드 스타일
  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    );
  }

  // 플랜 요약 카드
  Widget _buildPlanSummaryCard() {
    final targetAmount = _plan.targetAmount ?? 0;
    final currentAmount = _plan.currentAmount + _plan.currentAsset;
    final progressRate = targetAmount > 0
        ? (currentAmount / targetAmount * 100).clamp(0.0, 100.0)
        : 0.0;

    // 평균 페이스 계산 (플랜 시작일부터 현재까지의 일수)
    final now = DateTime.now();
    final startDate = _plan.startDate ?? now;
    final daysElapsed = now.difference(startDate).inDays;
    final averagePace = daysElapsed > 0
        ? (progressRate / daysElapsed).toStringAsFixed(2)
        : '0.00';

    // 평균 하루 저축 금액 계산
    final averageDailySaving = daysElapsed > 0
        ? (currentAmount / daysElapsed).round()
        : 0;

    // 목표 페이스 계산 (목표 달성까지 남은 일수 기준)
    final endDate = _plan.endDate ?? now.add(const Duration(days: 180));
    final totalDays = endDate.difference(startDate).inDays;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 순차적 차트 영역 (중간)
          _buildSequentialCharts(
            startDate: startDate,
            endDate: endDate,
            totalDays: totalDays,
            daysElapsed: daysElapsed,
          ),
          const SizedBox(height: 50), // 차트와 하단 정보 사이 패딩
          // 하단 정보: 평균 페이스와 평균 하루 저축 금액
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평균 페이스',
                      style: TextStyle(fontSize: 12, color: AppColors.subText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$averagePace% / 일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '평균 하루 저축 금액',
                      style: TextStyle(fontSize: 12, color: AppColors.subText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_nf.format(averageDailySaving)}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 순차적 차트 빌드
  Widget _buildSequentialCharts({
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required int daysElapsed,
  }) {
    // 하드코딩된 데이터 (나중에 실제 데이터로 교체 가능)
    // 1. 매일 일일소비 절제 달성률
    final restraintDays = (totalDays * 0.76).round(); // 76% 달성
    final restraintProgress = totalDays > 0
        ? (restraintDays / totalDays * 100).round()
        : 0;

    // 2. 두 번째 차트 (예: 목표 달성률)
    final targetProgress = 23; // 예시
    final targetDescription = '목표 금액의 ${targetProgress}%를 달성했어요!';

    // 3. 세 번째 차트 (예: 평균 저축률)
    final savingProgress = 68; // 예시
    final savingDescription = '평균 저축률 ${savingProgress}%를 유지하고 있어요!';

    final charts = [
      ChartData(
        title: '일일소비 절제 달성률',
        progress: restraintProgress / 100.0,
        color: const Color(0xFF0062FF),
        description: '플랜 기간 ${totalDays}일 중 총 ${restraintDays}일에 절제를 성공했어요!',
      ),
      ChartData(
        title: '목표 달성률',
        progress: targetProgress / 100.0,
        color: const Color(0xFF0062FF),
        description: targetDescription,
      ),
      ChartData(
        title: '평균 저축률',
        progress: savingProgress / 100.0,
        color: const Color(0xFF0062FF),
        description: savingDescription,
      ),
    ];

    return SequentialChartWidget(charts: charts);
  }

  // 감정 기록 통계 카드
  Widget _buildEmotionStatsCard() {
    if (_emotionCounts.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: _getCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '감정 기록이 없습니다',
                style: TextStyle(fontSize: 14, color: AppColors.subText),
              ),
            ),
          ],
        ),
      );
    }

    final sortedEmotions = _emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCount = _emotionCounts.values.fold(
      0,
          (sum, count) => sum + count,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sortedEmotions.length >= 3)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2위 (왼쪽)
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarSecondController,
                  itemController: _emotionItemSecondController,
                  title: _buildEmotionPodiumItem(
                    sortedEmotions[1],
                    2,
                    totalCount,
                  ),
                  height: 175 / 1.5, // 2위 높이
                  width: 77,
                  backgroundColor: const Color(0xFFC0C0C0), // 은색 (2위)
                  rank: 2, // 포디움 바에 숫자 표시
                ),
                const SizedBox(width: 3),
                // 1위 (중앙)
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarFirstController,
                  itemController: _emotionItemFirstController,
                  title: _buildEmotionPodiumItem(
                    sortedEmotions[0],
                    1,
                    totalCount,
                  ),
                  height: 175, // 1위 높이
                  width: 77,
                  backgroundColor: const Color(0xFFFFD700), // 금색 (1위)
                  rank: 1, // 포디움 바에 숫자 표시
                ),
                const SizedBox(width: 3),
                // 3위 (오른쪽)
                _buildAnimatedPodiumWithItem(
                  barController: _emotionBarThirdController,
                  itemController: _emotionItemThirdController,
                  title: _buildEmotionPodiumItem(
                    sortedEmotions[2],
                    3,
                    totalCount,
                  ),
                  height: 175 / 2.5, // 3위 높이
                  width: 77,
                  backgroundColor: const Color(0xFFCD7F32), // 동색 (3위)
                  rank: 3, // 포디움 바에 숫자 표시
                ),
              ],
            ),
          // 나머지 리스트 (4위부터) - 마지막에 나타남
          if (sortedEmotions.length > 3) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _emotionListController,
              builder: (context, child) {
                return Opacity(
                  opacity: _emotionListController.value,
                  child: Column(
                    children: sortedEmotions.skip(3).toList().asMap().entries.map((
                        entry,
                        ) {
                      final index = entry.key + 4; // 4위부터
                      final emotionEntry = entry.value;
                      final percentage =
                      (emotionEntry.value / totalCount * 100);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$index',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.subText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: Lottie.asset(
                                        _lottiePathForEmotion(emotionEntry.key),
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Text(
                                            emotionEntry.key,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _getEmotionColor(
                                                emotionEntry.key,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text(
                                          emotionEntry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.text,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${emotionEntry.value}회 • ${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.subText,
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
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // 소비 기록 통계 카드
  Widget _buildSpendingStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_categorySpending.isNotEmpty) ...[
            // 포디움: 상위 3개 (제일 위에 배치)
            Builder(
              builder: (context) {
                final sortedCategories =
                (_categorySpending.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                    .toList();

                if (sortedCategories.length >= 3) {
                  return Column(
                    children: [
                      // 포디움: 상위 3개 (3위 -> 2위 -> 1위 순서로 애니메이션)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 2위 (왼쪽)
                          _buildAnimatedPodiumWithItem(
                            barController: _categoryBarSecondController,
                            itemController: _categoryItemSecondController,
                            title: _buildCategoryPodiumItem(
                              sortedCategories[1],
                              2,
                            ),
                            height: 175 / 1.5, // 2위 높이
                            width: 77,
                            backgroundColor: const Color(0xFFC0C0C0), // 은색 (2위)
                            rank: 2, // 포디움 바에 숫자 표시
                          ),
                          const SizedBox(width: 3),
                          // 1위 (중앙)
                          _buildAnimatedPodiumWithItem(
                            barController: _categoryBarFirstController,
                            itemController: _categoryItemFirstController,
                            title: _buildCategoryPodiumItem(
                              sortedCategories[0],
                              1,
                            ),
                            height: 175, // 1위 높이
                            width: 77,
                            backgroundColor: const Color(0xFFFFD700), // 금색 (1위)
                            rank: 1, // 포디움 바에 숫자 표시
                          ),
                          const SizedBox(width: 3),
                          // 3위 (오른쪽)
                          _buildAnimatedPodiumWithItem(
                            barController: _categoryBarThirdController,
                            itemController: _categoryItemThirdController,
                            title: _buildCategoryPodiumItem(
                              sortedCategories[2],
                              3,
                            ),
                            height: 175 / 2.5, // 3위 높이
                            width: 77,
                            backgroundColor: const Color(0xFFCD7F32), // 동색 (3위)
                            rank: 3, // 포디움 바에 숫자 표시
                          ),
                        ],
                      ),
                      // 나머지 리스트 (4위부터) - 마지막에 나타남
                      if (sortedCategories.length > 3) ...[
                        const SizedBox(height: 24),
                        AnimatedBuilder(
                          animation: _categoryListController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _categoryListController.value,
                              child: Column(
                                children: sortedCategories
                                    .skip(3)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  final index = entry.key + 4; // 4위부터
                                  final categoryEntry = entry.value;

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$index',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.subText,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            categoryEntry.key,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_nf.format(categoryEntry.value.round())}원',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })
                                    .toList(),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  );
                } else {
                  // 3개 미만일 때는 리스트로 표시
                  return Column(
                    children: sortedCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final categoryEntry = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: index == 0
                                      ? AppColors.primary
                                      : AppColors.subText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                categoryEntry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ),
                            Text(
                              '${_nf.format(categoryEntry.value.round())}원',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: index == 0
                                    ? AppColors.primary
                                    : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // 최근 일지 기록 카드 (달력 형태) — 소통 페이지 달력·실제 기록 연동
  Widget _buildRecentDiariesCard() {
    return Consumer<CommunicationViewModel>(
      builder: (context, vm, _) {
        if (vm.selectedYear != _selectedYear ||
            vm.selectedMonth != _selectedMonth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.loadMonth(DateTime(_selectedYear, _selectedMonth, 1));
          });
        }
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: _getCardDecoration(),
          child: _buildDiaryCalendar(vm),
        );
      },
    );
  }

  // 달력 위젯 (소통 VM 연동: 실제 감정·소비 기록 표시, 날짜 탭 시 상세 모달)
  Widget _buildDiaryCalendar(CommunicationViewModel vm) {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 월 선택
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMonth == 1) {
                        _selectedMonth = 12;
                        _selectedYear--;
                      } else {
                        _selectedMonth--;
                      }
                    });
                    vm.loadMonth(DateTime(_selectedYear, _selectedMonth, 1));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_selectedYear년 $_selectedMonth월',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMonth == 12) {
                        _selectedMonth = 1;
                        _selectedYear++;
                      } else {
                        _selectedMonth++;
                      }
                    });
                    vm.loadMonth(DateTime(_selectedYear, _selectedMonth, 1));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 달력 그리드
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 요일 헤더
                Row(
                  children: ['일', '월', '화', '수', '목', '금', '토']
                      .map(
                        (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: day == '일' ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 8),
                // 달력 그리드
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cellW = constraints.maxWidth / 7;
                    const ratio = 1.15;
                    final gridH = (cellW / ratio) * 6;

                    return SizedBox(
                      height: gridH,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: ratio,
                        ),
                        itemCount: 42,
                        itemBuilder: (context, index) {
                          final day = index - firstWeekday + 1;
                          final isCurrentMonth = day > 0 && day <= daysInMonth;

                          if (!isCurrentMonth) return const SizedBox();

                          final hasEmotion = vm.hasEmotionRecord(day);
                          final emotionLabel = vm.emotionLabelForDay(day);

                          return GestureDetector(
                            onTap: () {
                              showDateDetailModal(
                                context: context,
                                vm: vm,
                                day: day,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (hasEmotion &&
                                      emotionLabel.trim().isNotEmpty)
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Lottie.asset(
                                        _lottiePathForEmotion(emotionLabel),
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Text(
                                          vm.emotionEmojiForDay(day),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!hasEmotion ||
                                      emotionLabel.trim().isEmpty)
                                    Text(
                                      '$day',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 감정 이모지 변환
  // 감정 포디움 아이템 빌더
  Widget _buildEmotionPodiumItem(
      MapEntry<String, int> emotionEntry,
      int rank,
      int totalCount,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 감정 Lottie
        SizedBox(
          width: 70,
          height: 70,
          child: Lottie.asset(
            _lottiePathForEmotion(emotionEntry.key),
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  emotionEntry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getEmotionColor(emotionEntry.key),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // 감정 이름
        Text(
          emotionEntry.key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // 횟수
        Text(
          '${emotionEntry.value}회',
          style: TextStyle(fontSize: 12, color: AppColors.subText),
        ),
      ],
    );
  }

  // 소비 카테고리 포디움 아이템 빌더
  Widget _buildCategoryPodiumItem(
      MapEntry<String, double> categoryEntry,
      int rank,
      ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 카테고리 이름
        Text(
          categoryEntry.key,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // 금액
        Text(
          '${_nf.format(categoryEntry.value.round())}원',
          style: TextStyle(fontSize: 12, color: AppColors.subText),
        ),
      ],
    );
  }

  // 포디움 바와 아이템을 분리한 애니메이션 위젯
  Widget _buildAnimatedPodiumWithItem({
    required AnimationController barController,
    required AnimationController itemController,
    required Widget title,
    required double height,
    required double width,
    required Color backgroundColor,
    int? rank, // 카테고리 포디움에 숫자 표시용
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 감정 아이템 (페이드인 + 스케일 애니메이션) - 카테고리는 빈 위젯
        SizedBox(
          width: width,
          child: Center(
            child: AnimatedBuilder(
              animation: itemController,
              builder: (context, child) {
                return Opacity(
                  opacity: itemController.value,
                  child: Transform.scale(
                    scale: 0.5 + (itemController.value * 0.5), // 0.5에서 1.0으로
                    child: title,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 포디움 바 (밑에서 올라오는 애니메이션)
        AnimatedBuilder(
          animation: barController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - barController.value) * 200),
              child: Opacity(
                opacity: barController.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3D 효과 (위쪽 면)
                    RotatedBox(
                      quarterTurns: 2,
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.02)
                          ..rotateX(3.14 / 10),
                        alignment: FractionalOffset.center,
                        child: Container(
                          height: 10,
                          width: width - 3,
                          color: backgroundColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    // 포디움 바 (숫자 표시)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(color: backgroundColor),
                        ),
                        // 포디움 바에 숫자 표시 (카테고리만)
                        if (rank != null)
                          Text(
                            '$rank',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case '좋음':
        return Colors.orange;
      case '슬픔':
        return Colors.blue;
      case '스트레스':
        return Colors.red;
      case '동기부여':
        return Colors.purple;
      case '평온':
        return Colors.green;
      case '아무 감정 없음':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _lottiePathForEmotion(String emotion) {
    switch (emotion) {
      case '평온':
        return 'assets/animations/emotion_calm.json';
      case '좋음':
      case '기쁨':
        return 'assets/animations/emotion_good.json';
      case '슬픔':
      case '피곤':
        return 'assets/animations/emotion_sad.json';
      case '스트레스':
      case '혼란':
      case '화남':
        return 'assets/animations/emotion_stress.json';
      case '동기부여':
      case '플렉스':
        return 'assets/animations/emotion_motivation.json';
      case '아무 감정 없음':
        return 'assets/animations/emotion_none.json';
      default:
        return 'assets/animations/emotion_calm.json'; // Fallback
    }
  }
}




