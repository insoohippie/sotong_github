import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sotong/view/pages/plan/plan_widgets/plan_celebration/sequential_chart_widget.dart';
import '../../../component/appbars/back_only_app_bar.dart';
import '../../../component/buttons/custom_button.dart';
import '../../../component/theme/app_colors.dart';
import '../../../component/theme/app_spacing.dart';
import '../../../view_model/communication/communication_view_model.dart';
import 'start_new_plan_flow.dart';
import '../communication/comm_widgets/date_detail_modal.dart';
import '../../../model/setting/past_plan_snapshot.dart';
import '../../../repository/past_plan_repository.dart';

/// ===========================================================================
/// 플랜 종합 대시보드 페이지
/// - 플랜 정보 요약 (목표 금액, 현재 금액, 진행률, 예상 완료일)
/// - 감정 기록 통계 (감정 분포, 최근 감정)
/// - 소비 기록 통계 (월별 소비, 카테고리별 소비)
/// - 일지 기록 (최근 일지)
/// - 인사이트/분석
/// ===========================================================================
class TotalPlanPage extends StatefulWidget {
  /// [snapshot]을 넘기면 "열람 모드": 해당 지난 플랜을 보여주고
  /// 하단 버튼이 '새로운 플랜 만들기' 대신 '뒤로가기'가 된다.
  /// 넘기지 않으면 "완료 모드": 최신 완료 플랜을 보여준다(기존 동작).
  const TotalPlanPage({super.key, this.snapshot});

  final PastPlanSnapshot? snapshot;

  @override
  State<TotalPlanPage> createState() => _TotalPlanPageState();
}

class _TotalPlanPageState extends State<TotalPlanPage>
    with TickerProviderStateMixin {
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');
  static const int _cardCount = 4;

  final PageController _pageController = PageController();
  final List<GlobalKey> _cardCaptureKeys =
      List.generate(_cardCount, (_) => GlobalKey());
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

  // 지난 플랜 스냅샷 데이터 (플랜 완료 시 저장된 실데이터)
  PastPlanSnapshot? _snapshot;
  Map<String, int> _emotionCounts = const {};
  Map<String, double> _categorySpending = const {};

  // 달력 상태
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadSnapshotData();
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

  /// 열람 모드 여부 (외부에서 스냅샷이 주입된 경우)
  bool get _isReviewMode => widget.snapshot != null;

  /// 주입된 스냅샷이 있으면 그것을, 없으면 가장 최근 완료 플랜을 불러와 카드 데이터를 채운다.
  void _loadSnapshotData() {
    if (widget.snapshot != null) {
      _snapshot = widget.snapshot;
    } else {
      final snapshots = PastPlanRepository().load();
      _snapshot = snapshots.isNotEmpty ? snapshots.last : null;
    }
    _emotionCounts = Map<String, int>.from(_snapshot?.emotionCounts ?? {});
    _categorySpending =
        Map<String, double>.from(_snapshot?.categorySpending ?? {});

    final start = _planStartDate;
    if (start != null) {
      _selectedYear = start.year;
      _selectedMonth = start.month;
    }
  }

  DateTime? get _planStartDate {
    final raw = _snapshot?.startDate;
    if (raw == null) return null;
    return DateTime(raw.year, raw.month, raw.day);
  }

  DateTime? get _planEndDate {
    final raw = _snapshot?.endDate ?? _snapshot?.completedAt;
    if (raw == null) return null;
    return DateTime(raw.year, raw.month, raw.day);
  }

  DateTime _monthStart(int year, int month) => DateTime(year, month, 1);

  bool get _canGoToPreviousMonth {
    final start = _planStartDate;
    if (start == null) return true;
    final current = _monthStart(_selectedYear, _selectedMonth);
    final planStartMonth = _monthStart(start.year, start.month);
    return current.isAfter(planStartMonth);
  }

  bool get _canGoToNextMonth {
    final end = _planEndDate;
    if (end == null) return true;
    final current = _monthStart(_selectedYear, _selectedMonth);
    final planEndMonth = _monthStart(end.year, end.month);
    return current.isBefore(planEndMonth);
  }

  bool _isDayInPlanRange(int day) {
    final date = DateTime(_selectedYear, _selectedMonth, day);
    final start = _planStartDate;
    final end = _planEndDate;
    if (start != null && date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;
    return true;
  }

  static const double _cardVerticalPadding = 12;

  Widget _buildCardPage(int pageIndex, Widget content) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: RepaintBoundary(
                key: _cardCaptureKeys[pageIndex],
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: _cardVerticalPadding,
                  ),
                  decoration: _getCardDecoration(),
                  child: content,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home_tab_navigator',
      (_) => false,
      arguments: 1,
    );
  }

  void _startNewPlan() {
    startNewPlanFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackOnlyAppBar(
        title: '나의 기록',
        onBack: _goBack,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 메인 콘텐츠 (플랜 정보)
            Column(
              children: [
                // 카드 슬라이드 영역
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {});
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
                      _buildCardPage(0, _buildPlanSummaryCard()),
                      _buildCardPage(1, _buildEmotionStatsCard()),
                      _buildCardPage(2, _buildSpendingStatsCard()),
                      _buildCardPage(3, _buildRecentDiariesCard()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _cardCount,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 8,
                      activeDotColor: AppColors.primary,
                      dotColor: Color(0xFFD9D9D9),
                    ),
                    onDotClicked: (index) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 120),
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

  Future<void> _shareCurrentCard() async {
    final pageIndex =
        (_pageController.page ?? _pageController.initialPage.toDouble())
            .round();
    final boundary = _cardCaptureKeys[pageIndex].currentContext
        ?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유할 화면을 불러오지 못했어요')),
      );
      return;
    }

    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/plan_record_$pageIndex.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      final planName = _snapshot?.planName ?? '플랜';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '소통 $planName 나의 기록',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공유하기에 실패했어요')),
      );
    }
  }

  // 하단 고정 네비게이션 바
  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    const shareGray = Color(0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: CustomButton(
                // 열람 모드(지난 플랜 돌아보기)에서는 새 플랜 대신 뒤로가기
                text: _isReviewMode ? '뒤로가기' : '새로운 플랜 만들기',
                padding: EdgeInsets.zero,
                onPressed: _isReviewMode ? _goBack : _startNewPlan,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              height: 60,
              child: ElevatedButton(
                onPressed: _shareCurrentCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: shareGray,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.ios_share, size: 22),
              ),
            ),
          ],
        ),
      ),
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

  // 플랜 요약 카드 (완료 스냅샷 실데이터)
  Widget _buildPlanSummaryCard() {
    final snapshot = _snapshot;
    final totalDays = snapshot?.daysTaken ?? 0;
    final averagePace = snapshot?.averagePace ?? '0.00';
    final averageDailySaving = snapshot?.averageDailySaving ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSequentialCharts(totalDays: totalDays),
        const SizedBox(height: 20),
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
      );
  }

  // 순차적 차트 빌드 (완료 스냅샷 실데이터)
  Widget _buildSequentialCharts({required int totalDays}) {
    // 1. 매일 일일소비 절제 달성률
    final restraintProgress = (_snapshot?.restraintProgress ?? 0).clamp(0, 100);
    final restraintDays = (totalDays * restraintProgress / 100).round();

    // 2. 목표 달성률 (조기 달성 시 100%를 넘을 수 있어 게이지만 100으로 클램프)
    final targetProgress = _snapshot?.targetProgress ?? 0;
    final targetDescription = '목표 금액의 $targetProgress%를 달성했어요!';

    // 3. 평균 저축률
    final savingProgress = (_snapshot?.savingProgress ?? 0).clamp(0, 100);
    final savingDescription = '평균 저축률 $savingProgress%를 유지했어요!';

    final charts = [
      ChartData(
        title: '일일소비 절제 달성률',
        progress: restraintProgress / 100.0,
        color: const Color(0xFF0062FF),
        description: '플랜 기간 ${totalDays}일 중 총 ${restraintDays}일에 절제를 성공했어요!',
      ),
      ChartData(
        title: '목표 달성률',
        progress: targetProgress.clamp(0, 100) / 100.0,
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
      return Center(
        child: Text(
          '감정 기록이 없습니다',
          style: TextStyle(fontSize: 14, color: AppColors.subText),
        ),
      );
    }

    final sortedEmotions = _emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCount = _emotionCounts.values.fold(
      0,
          (sum, count) => sum + count,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sortedEmotions.length >= 3)
            // 좁은 화면(가용 폭 < 237px)에서 포디움이 넘치지 않도록 축소
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
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
              ),
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
      );
  }

  // 소비 기록 통계 카드
  Widget _buildSpendingStatsCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                      // 좁은 화면(가용 폭 < 237px)에서 포디움이 넘치지 않도록 축소
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
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
                                backgroundColor:
                                    const Color(0xFFC0C0C0), // 은색 (2위)
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
                                backgroundColor:
                                    const Color(0xFFFFD700), // 금색 (1위)
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
                                backgroundColor:
                                    const Color(0xFFCD7F32), // 동색 (3위)
                                rank: 3, // 포디움 바에 숫자 표시
                              ),
                            ],
                          ),
                        ),
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
        return _buildDiaryCalendar(vm);
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 월 선택
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _canGoToPreviousMonth
                      ? () {
                          setState(() {
                            if (_selectedMonth == 1) {
                              _selectedMonth = 12;
                              _selectedYear--;
                            } else {
                              _selectedMonth--;
                            }
                          });
                          vm.loadMonth(
                            DateTime(_selectedYear, _selectedMonth, 1),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      color: _canGoToPreviousMonth
                          ? Colors.grey[700]
                          : Colors.grey[300],
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
                  onTap: _canGoToNextMonth
                      ? () {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                          });
                          vm.loadMonth(
                            DateTime(_selectedYear, _selectedMonth, 1),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right,
                      color: _canGoToNextMonth
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 달력 그리드
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                          final inPlanRange = _isDayInPlanRange(day);
                          final hasEmotion = vm.hasEmotionRecord(day);
                          final emotionLabel = vm.emotionLabelForDay(day);
                          final hasRecord =
                              hasEmotion || vm.spendingAmountForDay(day) > 0;

                          return GestureDetector(
                            onTap: inPlanRange && hasRecord
                                ? () {
                                    showDateDetailModal(
                                      context: context,
                                      vm: vm,
                                      day: day,
                                      allowSpendingRegistration: false,
                                      readOnly: true,
                                    );
                                  }
                                : null,
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (inPlanRange &&
                                      hasEmotion &&
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
                                  if (!inPlanRange ||
                                      !hasEmotion ||
                                      emotionLabel.trim().isEmpty)
                                    Text(
                                      '$day',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: inPlanRange
                                            ? Colors.black87
                                            : Colors.grey[300],
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




