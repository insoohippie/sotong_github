// @insoohippie - 통합 플랜 관리 페이지
// 플랜 이름, 목표금액, 보유금액을 한눈에 보고 수정할 수 있는 통합 관리 페이지
// 월 수입, 고정소비, 변동소비 입력 모달을 통합하여 관리

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../component/theme/app_colors.dart';
import '../../model/plan_info.dart';
import '../../model/ref_data.dart';
import '../../model/entry.dart';
import 'plan/chat_widgets/input_modal/input_modal_widget.dart';
import '../../component/inputs/custom_text_field.dart';
import '../../component/buttons/custom_button.dart';

/// ===========================================================================
/// 통합 플랜 관리 페이지
/// - 플랜 이름, 목표금액, 보유금액 표시 및 수정
/// - 3개 버튼으로 각 모달 연결 (월 수입, 고정소비, 변동소비)
/// - 전체 화면 슬라이드 애니메이션으로 통일된 UX 제공
/// - 미니멀한 디자인으로 구성
/// ===========================================================================
class TotalPlanPage extends StatefulWidget {
  const TotalPlanPage({super.key});

  State<TotalPlanPage> createState() => _TotalPlanPageState();
}

class _TotalPlanPageState extends State<TotalPlanPage>
    with TickerProviderStateMixin {
  // =============================== 상태 변수 ===============================

  // @insoohippie - 선택된 탭 인덱스 (0: 플랜 기본정보, 1: 사용자 정보)
  int _selectedTabIndex = 0;

  // @insoohippie - 페이지 컨트롤러 (탭 슬라이드 애니메이션용)
  late PageController _pageController;

  // @insoohippie - 인사이트 페이지 컨트롤러 (자동 슬라이드용)
  late PageController _insightsPageController;

  // @insoohippie - 인사이트 관련 상태
  int _currentInsightIndex = 0;
  Timer? _insightsTimer;
  late List<Map<String, dynamic>> _insights;

  // @insoohippie - 숫자 포맷터 (천자리 콤마)
  final NumberFormat _nf = NumberFormat.decimalPattern('ko_KR');

  // @insoohippie - 플랜 정보 (실제로는 Provider나 ViewModel에서 가져와야 함)
  PlanInfo _planInfo = PlanInfo(
    planName: '첫 번째 저축 계획',
    targetAmount: 10000000, // 1,000만원
    currentAmount: 500000, // 50만원
    currentAsset: 2000000, // 200만원
  );

  // @insoohippie - 참조 데이터 (수입/지출 항목들)
  RefData _refData = RefData(
    fixedIncomes: [
      Entry(idx: 0, category: '급여', amount: 3000000, type: EntryType.fixed),
      Entry(idx: 1, category: '부업', amount: 500000, type: EntryType.fixed),
    ],
    fixedConsumptions: [
      Entry(idx: 0, category: '월세', amount: 800000, type: EntryType.fixed),
      Entry(idx: 1, category: '관리비', amount: 100000, type: EntryType.fixed),
      Entry(idx: 2, category: '통신비', amount: 80000, type: EntryType.fixed),
    ],
    dailyConsumptions: [
      Entry(idx: 0, category: '식비', amount: 15000, type: EntryType.daily),
      Entry(idx: 1, category: '교통비', amount: 5000, type: EntryType.daily),
    ],
  );

  // @insoohippie - 모달 표시 상태
  bool _showIncomeModal = false;
  bool _showFixedCostModal = false;
  bool _showPlanNameModal = false;
  bool _showTargetAmountModal = false;
  bool _showCurrentAmountModal = false;
  bool _showVariableExpenseModal = false;

  // @insoohippie - 애니메이션 컨트롤러들 (슬라이드 애니메이션용)
  late AnimationController _incomeModalController;
  late AnimationController _fixedCostModalController;
  late AnimationController _variableExpenseModalController;
  late AnimationController _planNameModalController;
  late AnimationController _targetAmountModalController;
  late AnimationController _currentAmountModalController;

  // @insoohippie - 슬라이드 애니메이션 (아래에서 위로)
  late Animation<Offset> _incomeModalAnimation;
  late Animation<Offset> _fixedCostModalAnimation;
  late Animation<Offset> _variableExpenseModalAnimation;
  late Animation<Offset> _planNameModalAnimation;
  late Animation<Offset> _targetAmountModalAnimation;
  late Animation<Offset> _currentAmountModalAnimation;

  // @insoohippie - 배경 투명도 애니메이션 (0.0에서 0.54로)
  late Animation<double> _incomeBackgroundAnimation;
  late Animation<double> _fixedCostBackgroundAnimation;
  late Animation<double> _variableExpenseBackgroundAnimation;
  late Animation<double> _planNameBackgroundAnimation;
  late Animation<double> _targetAmountBackgroundAnimation;
  late Animation<double> _currentAmountBackgroundAnimation;

  // =============================== 생명주기 ===============================

  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _insightsPageController = PageController();
    _initializeInsights();
    _initializeAnimations();
    _startInsightsAutoSlide();
  }

  void dispose() {
    _pageController.dispose();
    _insightsPageController.dispose();
    _insightsTimer?.cancel();
    _disposeAnimations();
    super.dispose();
  }

  // =============================== 인사이트 초기화 ===============================

  // @insoohippie - 목표 인사이트 데이터 초기화
  void _initializeInsights() {
    final income = _totalFixedIncome;
    final expense = _totalFixedCost + _totalDailyCost;
    final savings = income - expense;
    final remainingAmount =
        (_planInfo.targetAmount ?? 0) - _planInfo.currentAmount;
    final estimatedMonths = savings > 0
        ? (remainingAmount / savings).ceil()
        : 0;
    final progressRate =
        (_planInfo.currentAmount / (_planInfo.targetAmount ?? 1) * 100);

    // 원본 인사이트 데이터
    final originalInsights = [
      {
        'title': '목표 달성률 ${progressRate.toStringAsFixed(1)}%',
        'description': '현재 목표의 ${progressRate.toStringAsFixed(1)}%를 달성했어요',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
      {
        'title': '월 저축률 ${(savings / income * 100).toStringAsFixed(0)}%',
        'description': '현재 저축률로 목표 달성이 가능해요',
        'icon': Icons.savings,
        'color': Colors.blue,
      },
      {
        'title': '예상 달성 기간 ${estimatedMonths}개월',
        'description': '현재 속도로 ${estimatedMonths}개월 후 목표 달성 예정이에요',
        'icon': Icons.calendar_today,
        'color': Colors.orange,
      },
      {
        'title': '목표까지 ${_nf.format(remainingAmount.toInt())}원',
        'description':
            '목표 달성을 위해 ${_nf.format(remainingAmount.toInt())}원이 더 필요해요',
        'icon': Icons.flag,
        'color': AppColors.primary,
      },
      {
        'title': '월 저축액 ${_nf.format(savings.toInt())}원',
        'description': '현재 월 ${_nf.format(savings.toInt())}원씩 저축하고 있어요',
        'icon': Icons.account_balance_wallet,
        'color': Colors.purple,
      },
    ];

    // 무한 스크롤을 위해 데이터를 여러 번 반복
    _insights = [];
    for (int i = 0; i < 5; i++) {
      _insights.addAll(originalInsights);
    }
  }

  // @insoohippie - 인사이트 자동 슬라이드 시작
  void _startInsightsAutoSlide() {
    _insightsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_insightsPageController.hasClients) {
        final nextPage = (_currentInsightIndex + 1) % _insights.length;
        _insightsPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // =============================== 애니메이션 초기화 ===============================

  // @insoohippie - 모든 애니메이션 컨트롤러와 애니메이션 초기화
  void _initializeAnimations() {
    // 애니메이션 컨트롤러 초기화 (300ms 지속시간)
    _incomeModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fixedCostModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _variableExpenseModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _planNameModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _targetAmountModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _currentAmountModalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 슬라이드 애니메이션 초기화 (아래에서 위로)
    _incomeModalAnimation = _createSlideAnimation(_incomeModalController);
    _fixedCostModalAnimation = _createSlideAnimation(_fixedCostModalController);
    _variableExpenseModalAnimation = _createSlideAnimation(
      _variableExpenseModalController,
    );
    _planNameModalAnimation = _createSlideAnimation(_planNameModalController);
    _targetAmountModalAnimation = _createSlideAnimation(
      _targetAmountModalController,
    );
    _currentAmountModalAnimation = _createSlideAnimation(
      _currentAmountModalController,
    );

    // 배경 투명도 애니메이션 초기화 (0.0에서 0.54로)
    _incomeBackgroundAnimation = _createBackgroundAnimation(
      _incomeModalController,
    );
    _fixedCostBackgroundAnimation = _createBackgroundAnimation(
      _fixedCostModalController,
    );
    _variableExpenseBackgroundAnimation = _createBackgroundAnimation(
      _variableExpenseModalController,
    );
    _planNameBackgroundAnimation = _createBackgroundAnimation(
      _planNameModalController,
    );
    _targetAmountBackgroundAnimation = _createBackgroundAnimation(
      _targetAmountModalController,
    );
    _currentAmountBackgroundAnimation = _createBackgroundAnimation(
      _currentAmountModalController,
    );
  }

  // @insoohippie - 슬라이드 애니메이션 생성 (아래에서 위로)
  Animation<Offset> _createSlideAnimation(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  // @insoohippie - 배경 투명도 애니메이션 생성
  Animation<double> _createBackgroundAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 0.54,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }

  // @insoohippie - 모든 애니메이션 컨트롤러 해제
  void _disposeAnimations() {
    _incomeModalController.dispose();
    _fixedCostModalController.dispose();
    _variableExpenseModalController.dispose();
    _planNameModalController.dispose();
    _targetAmountModalController.dispose();
    _currentAmountModalController.dispose();
  }

  // =============================== 계산된 속성 ===============================

  // @insoohippie - 총 고정 수입 계산
  double get _totalFixedIncome =>
      _refData.fixedIncomes.fold(0.0, (sum, e) => sum + e.amount);

  // @insoohippie - 총 고정 지출 계산
  double get _totalFixedCost =>
      _refData.fixedConsumptions.fold(0.0, (sum, e) => sum + e.amount);

  // @insoohippie - 총 변동 지출 계산 (30일 기준)
  double get _totalDailyCost =>
      _refData.dailyConsumptions.fold(0.0, (sum, e) => sum + e.amount) * 30;

  // =============================== 모달 제어 ===============================

  // @insoohippie - 수입 모달 열기
  void _openIncomeModal() {
    setState(() => _showIncomeModal = true);
    _incomeModalController.forward();
  }

  // @insoohippie - 수입 모달 닫기 (애니메이션 완료 후 상태 변경)
  void _closeIncomeModal() {
    _incomeModalController.reverse().then((_) {
      if (mounted) {
        setState(() => _showIncomeModal = false);
      }
    });
  }

  // @insoohippie - 고정소비 모달 열기
  void _openFixedCostModal() {
    setState(() => _showFixedCostModal = true);
    _fixedCostModalController.forward();
  }

  // @insoohippie - 고정소비 모달 닫기
  void _closeFixedCostModal() {
    _fixedCostModalController.reverse().then((_) {
      if (mounted) {
        setState(() => _showFixedCostModal = false);
      }
    });
  }

  // @insoohippie - 변동소비 모달 열기
  void _openVariableExpenseModal() {
    setState(() => _showVariableExpenseModal = true);
    _variableExpenseModalController.forward();
  }

  // @insoohippie - 변동소비 모달 닫기
  void _closeVariableExpenseModal() {
    _variableExpenseModalController.reverse().then((_) {
      if (mounted) {
        setState(() => _showVariableExpenseModal = false);
      }
    });
  }

  // @insoohippie - 플랜 이름 모달 열기
  void _openPlanNameModal() {
    setState(() => _showPlanNameModal = true);
    _planNameModalController.forward();
  }

  // @insoohippie - 플랜 이름 모달 닫기
  void _closePlanNameModal() {
    _planNameModalController.reverse().then((_) {
      setState(() => _showPlanNameModal = false);
    });
  }

  // @insoohippie - 목표금액 모달 열기
  void _openTargetAmountModal() {
    setState(() => _showTargetAmountModal = true);
    _targetAmountModalController.forward();
  }

  // @insoohippie - 목표금액 모달 닫기
  void _closeTargetAmountModal() {
    _targetAmountModalController.reverse().then((_) {
      setState(() => _showTargetAmountModal = false);
    });
  }

  // @insoohippie - 보유금액 모달 열기
  void _openCurrentAmountModal() {
    setState(() => _showCurrentAmountModal = true);
    _currentAmountModalController.forward();
  }

  // @insoohippie - 보유금액 모달 닫기
  void _closeCurrentAmountModal() {
    _currentAmountModalController.reverse().then((_) {
      setState(() => _showCurrentAmountModal = false);
    });
  }

  // =============================== 데이터 업데이트 ===============================

  // @insoohippie - 수입 데이터 업데이트
  void _updateIncomeData(List<Entry> items, double total) {
    setState(() {
      _refData.fixedIncomes = items;
      _planInfo.fixedIncomeSum = total;
    });
  }

  // @insoohippie - 고정소비 데이터 업데이트
  void _updateFixedCostData(List<Entry> items, double total) {
    setState(() {
      _refData.fixedConsumptions = items;
      _planInfo.fixedConsumptionSum = total;
    });
  }

  // @insoohippie - 변동소비 데이터 업데이트
  void _updateVariableExpenseData(List<Entry> items, double total) {
    setState(() {
      _refData.variableConsumptions = items;
      _planInfo.variableConsumptionSum = total;
    });
  }

  // @insoohippie - 플랜 이름 업데이트
  void _updatePlanName(String newName) {
    setState(() {
      _planInfo.planName = newName;
    });
  }

  // @insoohippie - 목표금액 업데이트
  void _updateTargetAmount(double newAmount) {
    setState(() {
      _planInfo.targetAmount = newAmount;
    });
  }

  // @insoohippie - 보유금액 업데이트
  void _updateCurrentAmount(double newAmount) {
    setState(() {
      _planInfo.currentAmount = newAmount;
    });
  }

  // =============================== UI 빌드 ===============================

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // @insoohippie - 메인 컨텐츠 (헤더, 플랜 현황, 탭 바, 탭 컨텐츠)
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildPlanSummaryContainer(), // @insoohippie - 플랜 현황 컨테이너 추가
                _buildTabBar(),
                _buildTabContent(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // @insoohippie - 수입 입력 모달 (전체 화면 슬라이드 애니메이션)
          if (_showIncomeModal)
            _buildAnimatedModal(
              animation: _incomeBackgroundAnimation,
              slideAnimation: _incomeModalAnimation,
              child: InputModalWidget(
                isOpen: _showIncomeModal,
                onClose: _closeIncomeModal,
                title: '월 수입 입력하기',
                placeholder: '수입 카테고리',
                type: EntryType.fixed,
                onComplete: _updateIncomeData,
              ),
            ),

          // @insoohippie - 고정소비 입력 모달
          if (_showFixedCostModal)
            _buildAnimatedModal(
              animation: _fixedCostBackgroundAnimation,
              slideAnimation: _fixedCostModalAnimation,
              child: InputModalWidget(
                isOpen: _showFixedCostModal,
                onClose: _closeFixedCostModal,
                title: '고정 소비 입력하기',
                placeholder: '고정 소비 항목',
                type: EntryType.fixed,
                onComplete: _updateFixedCostData,
              ),
            ),

          // @insoohippie - 플랜 이름 수정 모달
          if (_showPlanNameModal)
            _buildAnimatedModal(
              animation: _planNameBackgroundAnimation,
              slideAnimation: _planNameModalAnimation,
              child: _buildFullScreenModal(
                isOpen: _showPlanNameModal,
                onClose: _closePlanNameModal,
                title: '플랜 이름 수정',
                child: _buildPlanNameModalContent(),
              ),
            ),

          // @insoohippie - 목표금액 수정 모달
          if (_showTargetAmountModal)
            _buildAnimatedModal(
              animation: _targetAmountBackgroundAnimation,
              slideAnimation: _targetAmountModalAnimation,
              child: _buildFullScreenModal(
                isOpen: _showTargetAmountModal,
                onClose: _closeTargetAmountModal,
                title: '목표 금액 수정',
                child: _buildTargetAmountModalContent(),
              ),
            ),

          // @insoohippie - 보유금액 수정 모달
          if (_showCurrentAmountModal)
            _buildAnimatedModal(
              animation: _currentAmountBackgroundAnimation,
              slideAnimation: _currentAmountModalAnimation,
              child: _buildFullScreenModal(
                isOpen: _showCurrentAmountModal,
                onClose: _closeCurrentAmountModal,
                title: '보유 금액 수정',
                child: _buildCurrentAmountModalContent(),
              ),
            ),

          // @insoohippie - 변동소비 입력 모달
          if (_showVariableExpenseModal)
            _buildAnimatedModal(
              animation: _variableExpenseBackgroundAnimation,
              slideAnimation: _variableExpenseModalAnimation,
              child: InputModalWidget(
                isOpen: _showVariableExpenseModal,
                onClose: _closeVariableExpenseModal,
                title: '하루 사용 금액',
                placeholder: '변동소비 항목',
                type: EntryType.daily,
                onComplete: _updateVariableExpenseData,
              ),
            ),
        ],
      ),
    );
  }

  // =============================== 모달 위젯 ===============================

  // @insoohippie - 애니메이션이 적용된 모달 래퍼
  Widget _buildAnimatedModal({
    required Animation<double> animation,
    required Animation<Offset> slideAnimation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Material(
          color: Colors.black.withOpacity(animation.value),
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }

  // @insoohippie - 전체 화면 모달 (플랜 정보 수정용)
  Widget _buildFullScreenModal({
    required bool isOpen,
    required VoidCallback onClose,
    required String title,
    required Widget child,
  }) {
    if (!isOpen) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // @insoohippie - 헤더 (뒤로가기 버튼)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  InkWell(
                    onTap: onClose,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
            // @insoohippie - 모달 내용
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  // =============================== 모달 컨텐츠 ===============================

  // @insoohippie - 플랜 이름 수정 모달 컨텐츠
  Widget _buildPlanNameModalContent() {
    final TextEditingController controller = TextEditingController(
      text: _planInfo.planName ?? '',
    );

    return Column(
      children: [
        // @insoohippie - 제목 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '플랜 이름을 입력해주세요',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDADADA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '저축 목표에 맞는 이름을 설정해주세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // @insoohippie - 입력 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomTextField(
            controller: controller,
            hintText: '예: 유럽여행 자금',
            height: 60,
          ),
        ),
        const Spacer(),
        // @insoohippie - 푸터 (완료 버튼)
        _buildModalFooter(
          onPressed: () {
            _updatePlanName(controller.text);
            _closePlanNameModal();
          },
        ),
      ],
    );
  }

  // @insoohippie - 목표금액 수정 모달 컨텐츠
  Widget _buildTargetAmountModalContent() {
    final TextEditingController controller = TextEditingController(
      text: _planInfo.targetAmount?.toInt().toString() ?? '0',
    );

    // @insoohippie - 천자리 단위 콤마 포맷터 (숫자만 허용)
    final thousandsFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'[0-9]'),
    );

    // @insoohippie - 숫자 포맷팅 함수
    String _formatNumber(String value) {
      if (value.isEmpty) return '';
      final number = int.tryParse(value);
      if (number == null) return value;
      return NumberFormat('#,###').format(number);
    }

    return Column(
      children: [
        // @insoohippie - 제목 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '목표 금액을 입력해주세요',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDADADA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '달성하고 싶은 목표 금액을 설정해주세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // @insoohippie - 입력 영역 (천자리 콤마 자동 포맷팅)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomTextField(
            controller: controller,
            hintText: '예: 10,000,000',
            height: 60,
            keyboardType: TextInputType.number,
            inputFormatters: [thousandsFormatter],
            onChanged: (value) {
              final cleanValue = value.replaceAll(',', '');
              final formattedValue = _formatNumber(cleanValue);
              if (formattedValue != value) {
                controller.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(
                    offset: formattedValue.length,
                  ),
                );
              }
            },
          ),
        ),
        const Spacer(),
        // @insoohippie - 푸터 (완료 버튼)
        _buildModalFooter(
          onPressed: () {
            final cleanText = controller.text.replaceAll(',', '');
            final amount = double.tryParse(cleanText) ?? 0;
            if (amount > 0) {
              _updateTargetAmount(amount);
              _closeTargetAmountModal();
            }
          },
        ),
      ],
    );
  }

  // @insoohippie - 보유금액 수정 모달 컨텐츠
  Widget _buildCurrentAmountModalContent() {
    final TextEditingController controller = TextEditingController(
      text: _planInfo.currentAmount.toInt().toString(),
    );

    // @insoohippie - 천자리 단위 콤마 포맷터 (음수 포함)
    final thousandsFormatter = FilteringTextInputFormatter.allow(
      RegExp(r'^-?[0-9]*'),
    );

    // @insoohippie - 숫자 포맷팅 함수 (음수 지원)
    String _formatNumber(String value) {
      if (value.isEmpty) return '';
      final isNegative = value.startsWith('-');
      final cleanValue = isNegative ? value.substring(1) : value;
      final number = int.tryParse(cleanValue);
      if (number == null) return value;
      final formatted = NumberFormat('#,###').format(number);
      return isNegative ? '-$formatted' : formatted;
    }

    return Column(
      children: [
        // @insoohippie - 제목 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '보유 금액을 입력해주세요',
                style: TextStyle(
                  fontFamily: 'Pretendard Variable',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDADADA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      '부채가 있으시면, -를 붙이고 금액을 적어주세요',
                      style: TextStyle(
                        fontFamily: 'Pretendard Variable',
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // @insoohippie - 입력 영역 (음수 지원, 천자리 콤마 자동 포맷팅)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomTextField(
            controller: controller,
            hintText: '예: 5,000,000 또는 -300,000',
            height: 60,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            inputFormatters: [thousandsFormatter],
            onChanged: (value) {
              final cleanValue = value.replaceAll(',', '');
              final formattedValue = _formatNumber(cleanValue);
              if (formattedValue != value) {
                controller.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(
                    offset: formattedValue.length,
                  ),
                );
              }
            },
          ),
        ),
        const Spacer(),
        // @insoohippie - 푸터 (완료 버튼)
        _buildModalFooter(
          onPressed: () {
            final cleanText = controller.text.replaceAll(',', '');
            final amount = double.tryParse(cleanText) ?? 0;
            _updateCurrentAmount(amount);
            _closeCurrentAmountModal();
          },
        ),
      ],
    );
  }

  // @insoohippie - 모달 푸터 (완료 버튼이 포함된 네비게이션 바)
  Widget _buildModalFooter({required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(text: '완료', onPressed: onPressed),
    );
  }

  // =============================== 메인 UI 컴포넌트 ===============================

  // @insoohippie - 플랜 핵심 피규어 컨테이너
  Widget _buildPlanSummaryContainer() {
    final income = _totalFixedIncome;
    final expense = _totalFixedCost + _totalDailyCost;
    final savings = income - expense;
    final remainingAmount =
        (_planInfo.targetAmount ?? 0) - _planInfo.currentAmount;
    final estimatedMonths = savings > 0
        ? (remainingAmount / savings).ceil()
        : 0;
    final progressRate =
        (_planInfo.currentAmount / (_planInfo.targetAmount ?? 1) * 100);
    final savingsRate = income > 0 ? (savings / income * 100).toDouble() : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // @insoohippie - 핵심 지표 2x2 그리드
          _buildKeyMetricsGrid(progressRate, savingsRate, estimatedMonths),
          const SizedBox(height: 12),
          // @insoohippie - 동적 애니메이션 바
          _buildInsightsContainer(),
        ],
      ),
    );
  }

  // @insoohippie - 핵심 지표 2x2 그리드
  Widget _buildKeyMetricsGrid(
    double progressRate,
    double savingsRate,
    int estimatedMonths,
  ) {
    return Column(
      children: [
        // @insoohippie - 첫 번째 행 (목표 금액, 현재 금액)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '목표 금액',
                '${_nf.format((_planInfo.targetAmount ?? 0).toInt())}원',
                Icons.flag,
                Colors.blue,
                '목표 달성까지',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                '현재 금액',
                '${_nf.format(_planInfo.currentAmount.toInt())}원',
                Icons.account_balance_wallet,
                Colors.green,
                '${progressRate.toStringAsFixed(1)}% 달성',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // @insoohippie - 두 번째 행 (월 저축액, 예상 완료일)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                '월 저축액',
                '${_nf.format((_totalFixedIncome - _totalFixedCost - _totalDailyCost).toInt())}원',
                Icons.savings,
                Colors.purple,
                '${savingsRate.toStringAsFixed(0)}% 저축률',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                '예상 완료일',
                estimatedMonths > 0 ? '${estimatedMonths}개월 후' : '계산 불가',
                Icons.calendar_today,
                Colors.orange,
                estimatedMonths > 0 ? '목표 달성 예정' : '데이터 부족',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // @insoohippie - 개별 지표 카드
  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard Variable',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6C757D),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // @insoohippie - 목표 인사이트 컨테이너 (자동 슬라이드)
  Widget _buildInsightsContainer() {
    return Container(
      height: 70,
      child: PageView.builder(
        controller: _insightsPageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentInsightIndex = index;
          });
        },
        itemCount: _insights.length,
        itemBuilder: (context, index) {
          final insight = _insights[index];
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: insight['color'].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(insight['icon'], color: insight['color'], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        insight['title'],
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight['description'],
                        style: const TextStyle(
                          fontFamily: 'Pretendard Variable',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C757D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // @insoohippie - 탭 바 (플랜 기본정보 | 사용자 정보)
  Widget _buildTabBar() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5, // 화면 너비의 50%
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton('플랜 기본정보', 0)),
            Expanded(child: _buildTabButton('사용자 정보', 1)),
          ],
        ),
      ),
    );
  }

  // @insoohippie - 탭 버튼
  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard Variable',
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFF6C757D),
          ),
        ),
      ),
    );
  }

  // @insoohippie - 탭 컨텐츠 (PageView로 슬라이드 애니메이션)
  Widget _buildTabContent() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        children: [_buildPlanBasicInfoTab(), _buildUserInfoTab()],
      ),
    );
  }

  // @insoohippie - 플랜 기본정보 탭
  Widget _buildPlanBasicInfoTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildPlanNameCard(),
          const SizedBox(height: 16),
          _buildTargetAmountCard(),
          const SizedBox(height: 16),
          _buildCurrentAmountCard(),
        ],
      ),
    );
  }

  // @insoohippie - 사용자 정보 탭
  Widget _buildUserInfoTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildIncomeButton(),
          const SizedBox(height: 16),
          _buildFixedCostButton(),
          const SizedBox(height: 16),
          _buildVariableExpenseButton(),
        ],
      ),
    );
  }

  // @insoohippie - 플랜 이름 카드
  Widget _buildPlanNameCard() {
    return _buildInfoCard(
      icon: Icons.edit_outlined,
      title: '플랜 이름',
      value: _planInfo.planName ?? '플랜 이름 없음',
      onTap: _openPlanNameModal,
    );
  }

  // @insoohippie - 목표 금액 카드
  Widget _buildTargetAmountCard() {
    return _buildInfoCard(
      icon: Icons.flag_outlined,
      title: '목표 금액',
      value: '${_nf.format(_planInfo.targetAmount?.toInt() ?? 0)}원',
      onTap: _openTargetAmountModal,
    );
  }

  // @insoohippie - 보유 금액 카드
  Widget _buildCurrentAmountCard() {
    final amount = _planInfo.currentAmount;
    final color = amount >= 0 ? AppColors.primary : Colors.red;

    return _buildInfoCard(
      icon: Icons.account_balance_wallet_outlined,
      title: '보유 금액',
      value: '${_nf.format(amount.toInt())}원',
      onTap: _openCurrentAmountModal,
      valueColor: color,
    );
  }

  // @insoohippie - 수입 입력 버튼
  Widget _buildIncomeButton() {
    return _buildActionButton(
      icon: Icons.account_balance_outlined,
      title: '월 수입 입력하기',
      subtitle: '총 ${_nf.format(_totalFixedIncome.toInt())}원',
      onTap: _openIncomeModal,
    );
  }

  // @insoohippie - 고정소비 입력 버튼
  Widget _buildFixedCostButton() {
    return _buildActionButton(
      icon: Icons.home_outlined,
      title: '월 고정소비 입력하기',
      subtitle: '총 ${_nf.format(_totalFixedCost.toInt())}원',
      onTap: _openFixedCostModal,
    );
  }

  // @insoohippie - 변동소비 입력 버튼
  Widget _buildVariableExpenseButton() {
    return _buildActionButton(
      icon: Icons.shopping_cart_outlined,
      title: '월 변동소비 입력하기',
      subtitle: '총 ${_nf.format(_totalDailyCost.toInt())}원',
      onTap: _openVariableExpenseModal,
    );
  }

  // @insoohippie - 정보 카드 (플랜 기본정보용)
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
    Color? valueColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF6C757D)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6C757D),
            ),
          ],
        ),
      ),
    );
  }

  // @insoohippie - 액션 버튼 (사용자 정보용)
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF6C757D)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Pretendard Variable',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6C757D),
            ),
          ],
        ),
      ),
    );
  }

  // @insoohippie - 헤더 (뒤로가기 버튼 + 제목)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const Text(
            '플랜 관리',
            style: TextStyle(
              fontFamily: 'Pretendard Variable',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 20), // @insoohippie - 뒤로가기 버튼과 균형 맞추기
        ],
      ),
    );
  }
}
