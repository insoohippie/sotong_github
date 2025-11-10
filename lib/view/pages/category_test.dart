import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sotong_local/component/theme/app_colors.dart';
import 'package:sotong_local/model/entry.dart';
import './plan/chat_widgets/input_modal/input_modal_widget.dart';
import './category/category_state_manager.dart';

/// 플랜챗뷰의 3개 모달(월수입, 월고정소비, 일변동소비)을 통합 관리하는 테스트 페이지
class CategoryTestPage extends StatefulWidget {
  const CategoryTestPage({Key? key}) : super(key: key);

  @override
  State<CategoryTestPage> createState() => _CategoryTestPageState();
}

class _CategoryTestPageState extends State<CategoryTestPage>
    with TickerProviderStateMixin {
  // =============================== 상태 변수 ===============================

  // 3개 모달의 표시 상태
  bool _showIncomeModal = false;
  bool _showFixedCostModal = false;
  bool _showDailySpendingModal = false;

  // 애니메이션 컨트롤러들
  late AnimationController _incomeModalController;
  late AnimationController _fixedCostModalController;
  late AnimationController _dailySpendingModalController;

  // 애니메이션들
  late Animation<Offset> _incomeModalAnimation;
  late Animation<Offset> _fixedCostModalAnimation;
  late Animation<Offset> _dailySpendingModalAnimation;

  late Animation<double> _incomeBackgroundAnimation;
  late Animation<double> _fixedCostBackgroundAnimation;
  late Animation<double> _dailySpendingBackgroundAnimation;

  // 사용자 입력 카테고리 저장
  List<String> _customIncomeCategories = [];
  List<String> _customFixedExpenseCategories = [];
  List<String> _customDailyExpenseCategories = [];

  // 카테고리별 이모지 저장
  Map<String, String> _incomeCategoryEmojis = {};
  Map<String, String> _fixedExpenseCategoryEmojis = {};
  Map<String, String> _dailyExpenseCategoryEmojis = {};

  // =============================== 라이프사이클 ===============================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCategoryData();
  }

  // 카테고리 데이터 로드 (CategoryStateManager에서)
  void _loadCategoryData() {
    setState(() {
      _customIncomeCategories = List.from(
        CategoryStateManager.customIncomeCategories,
      );
      _customFixedExpenseCategories = List.from(
        CategoryStateManager.customFixedExpenseCategories,
      );
      _customDailyExpenseCategories = List.from(
        CategoryStateManager.customDailyExpenseCategories,
      );

      _incomeCategoryEmojis = Map.from(
        CategoryStateManager.incomeCategoryEmojis,
      );
      _fixedExpenseCategoryEmojis = Map.from(
        CategoryStateManager.fixedExpenseCategoryEmojis,
      );
      _dailyExpenseCategoryEmojis = Map.from(
        CategoryStateManager.dailyExpenseCategoryEmojis,
      );
    });
  }

  @override
  void dispose() {
    try {
      _incomeModalController.dispose();
      _fixedCostModalController.dispose();
      _dailySpendingModalController.dispose();
    } catch (e) {
      // dispose 오류 무시
    }
    super.dispose();
  }

  void _initializeAnimations() {
    // 수입 모달 애니메이션
    _incomeModalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _incomeModalAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _incomeModalController,
            curve: Curves.easeOut,
          ),
        );
    _incomeBackgroundAnimation = CurvedAnimation(
      parent: _incomeModalController,
      curve: Curves.easeOut,
    );

    // 고정소비 모달 애니메이션
    _fixedCostModalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fixedCostModalAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _fixedCostModalController,
            curve: Curves.easeOut,
          ),
        );
    _fixedCostBackgroundAnimation = CurvedAnimation(
      parent: _fixedCostModalController,
      curve: Curves.easeOut,
    );

    // 일변동소비 모달 애니메이션
    _dailySpendingModalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dailySpendingModalAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _dailySpendingModalController,
            curve: Curves.easeOut,
          ),
        );
    _dailySpendingBackgroundAnimation = CurvedAnimation(
      parent: _dailySpendingModalController,
      curve: Curves.easeOut,
    );
  }

  // =============================== 모달 제어 ===============================

  void _openIncomeModal() {
    if (!mounted) return;
    setState(() => _showIncomeModal = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _incomeModalController.status != AnimationStatus.completed) {
        _incomeModalController.forward();
      }
    });
  }

  void _closeIncomeModal() {
    if (!mounted) return;
    _incomeModalController
        .reverse()
        .then((_) {
          if (mounted) {
            setState(() => _showIncomeModal = false);
          }
        })
        .catchError((_) {
          // 애니메이션 오류 무시
        });
  }

  void _openFixedCostModal() {
    if (!mounted) return;
    setState(() => _showFixedCostModal = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _fixedCostModalController.status != AnimationStatus.completed) {
        _fixedCostModalController.forward();
      }
    });
  }

  void _closeFixedCostModal() {
    if (!mounted) return;
    _fixedCostModalController
        .reverse()
        .then((_) {
          if (mounted) {
            setState(() => _showFixedCostModal = false);
          }
        })
        .catchError((_) {
          // 애니메이션 오류 무시
        });
  }

  void _openDailySpendingModal() {
    if (!mounted) return;
    setState(() => _showDailySpendingModal = true);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _dailySpendingModalController.status != AnimationStatus.completed) {
        _dailySpendingModalController.forward();
      }
    });
  }

  void _closeDailySpendingModal() {
    if (!mounted) return;
    _dailySpendingModalController
        .reverse()
        .then((_) {
          if (mounted) {
            setState(() => _showDailySpendingModal = false);
          }
        })
        .catchError((_) {
          // 애니메이션 오류 무시
        });
  }

  // =============================== 콜백 함수들 ===============================

  void _updateIncomeData(List<Entry> items, double total) {
    print('수입 데이터 업데이트: $items, 총액: $total');
    _closeIncomeModal();
  }

  void _updateFixedCostData(List<Entry> items, double total) {
    print('고정소비 데이터 업데이트: $items, 총액: $total');
    _closeFixedCostModal();
  }

  void _updateDailySpendingData(List<Entry> items, double total) {
    print('일변동소비 데이터 업데이트: $items, 총액: $total');
    _closeDailySpendingModal();
  }

  void _openIncomeCategorySettings() {
    Navigator.of(context).pushNamed('/income_category');
  }

  void _openFixedExpenseCategorySettings() {
    Navigator.of(context).pushNamed('/fixed_expense_category');
  }

  void _openDailyExpenseCategorySettings() {
    Navigator.of(context).pushNamed('/daily_expense_category');
  }

  // 사용자 입력 카테고리 추가 콜백들
  void _addCustomIncomeCategory(String category) {
    setState(() {
      if (!_customIncomeCategories.contains(category)) {
        _customIncomeCategories.add(category);

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomIncomeCategory(category);
      }
    });
  }

  void _addCustomFixedExpenseCategory(String category) {
    setState(() {
      if (!_customFixedExpenseCategories.contains(category)) {
        _customFixedExpenseCategories.add(category);

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomFixedExpenseCategory(category);
      }
    });
  }

  void _addCustomDailyExpenseCategory(String category) {
    setState(() {
      if (!_customDailyExpenseCategories.contains(category)) {
        _customDailyExpenseCategories.add(category);

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomDailyExpenseCategory(category);
      }
    });
  }

  // 카테고리와 이모지를 함께 추가하는 콜백들
  void _addCustomIncomeCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customIncomeCategories.contains(category)) {
        _customIncomeCategories.add(category);
        _incomeCategoryEmojis[category] = emoji;

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomIncomeCategory(category);
        CategoryStateManager.setIncomeCategoryEmoji(category, emoji);
      }
    });
  }

  void _addCustomFixedExpenseCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customFixedExpenseCategories.contains(category)) {
        _customFixedExpenseCategories.add(category);
        _fixedExpenseCategoryEmojis[category] = emoji;

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomFixedExpenseCategory(category);
        CategoryStateManager.setFixedExpenseCategoryEmoji(category, emoji);
      }
    });
  }

  void _addCustomDailyExpenseCategoryWithEmoji(String category, String emoji) {
    setState(() {
      if (!_customDailyExpenseCategories.contains(category)) {
        _customDailyExpenseCategories.add(category);
        _dailyExpenseCategoryEmojis[category] = emoji;

        // 전역 상태에도 동기화
        CategoryStateManager.addCustomDailyExpenseCategory(category);
        CategoryStateManager.setDailyExpenseCategoryEmoji(category, emoji);
      }
    });
  }

  // 사용자 입력 카테고리 삭제 콜백들
  void _removeCustomIncomeCategory(String category) {
    setState(() {
      _customIncomeCategories.remove(category);
      _incomeCategoryEmojis.remove(category);

      // 전역 상태에도 동기화
      CategoryStateManager.removeCustomIncomeCategory(category);
    });
  }

  void _removeCustomFixedExpenseCategory(String category) {
    setState(() {
      _customFixedExpenseCategories.remove(category);
      _fixedExpenseCategoryEmojis.remove(category);

      // 전역 상태에도 동기화
      CategoryStateManager.removeCustomFixedExpenseCategory(category);
    });
  }

  void _removeCustomDailyExpenseCategory(String category) {
    setState(() {
      _customDailyExpenseCategories.remove(category);
      _dailyExpenseCategoryEmojis.remove(category);

      // 전역 상태에도 동기화
      CategoryStateManager.removeCustomDailyExpenseCategory(category);
    });
  }

  // =============================== UI 빌드 ===============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '플랜 모달 테스트',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '플랜챗뷰의 3개 모달을 테스트할 수 있습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 32),

                // 월 수입 버튼
                _buildModalButton(
                  title: '월 수입',
                  subtitle: '매달 반복적으로 들어오는 수입',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: _openIncomeModal,
                ),
                const SizedBox(height: 16),

                // 월 고정소비 버튼
                _buildModalButton(
                  title: '월 고정소비',
                  subtitle: '매달 빠짐없이 자동으로 지출되는 비용',
                  icon: Icons.home_outlined,
                  onTap: _openFixedCostModal,
                ),
                const SizedBox(height: 16),

                // 일 변동소비 버튼
                _buildModalButton(
                  title: '일 변동소비',
                  subtitle: '하루 지출을 입력하면 월(30일) 변동예산을 자동으로 계산',
                  icon: Icons.shopping_cart_outlined,
                  onTap: _openDailySpendingModal,
                ),
              ],
            ),
          ),

          // 월 수입 모달
          if (_showIncomeModal)
            _buildAnimatedModal(
              animation: _incomeBackgroundAnimation,
              slideAnimation: _incomeModalAnimation,
              child: InputModalWidget(
                isOpen: _showIncomeModal,
                onClose: _closeIncomeModal,
                title: '월 수입 입력하기',
                placeholder: '수입 카테고리',
                hintText: '예: 월급, 아르바이트, 용돈 등',
                type: EntryType.fixed,
                onCategorySettingsTap: _openIncomeCategorySettings,
                onComplete: _updateIncomeData,
                customCategories: _customIncomeCategories,
                onCustomCategoryAdded: _addCustomIncomeCategory,
                onCustomCategoryRemoved: _removeCustomIncomeCategory,
                onCustomCategoryAddedWithEmoji:
                    _addCustomIncomeCategoryWithEmoji,
                categoryEmojis: _incomeCategoryEmojis,
              ),
            ),

          // 월 고정소비 모달
          if (_showFixedCostModal)
            _buildAnimatedModal(
              animation: _fixedCostBackgroundAnimation,
              slideAnimation: _fixedCostModalAnimation,
              child: InputModalWidget(
                isOpen: _showFixedCostModal,
                onClose: _closeFixedCostModal,
                title: '고정 소비 입력하기',
                placeholder: '고정 소비 항목',
                hintText: '예: 월세, 관리비, 보험료 등',
                type: EntryType.fixed,
                onCategorySettingsTap: _openFixedExpenseCategorySettings,
                onComplete: _updateFixedCostData,
                customCategories: _customFixedExpenseCategories,
                onCustomCategoryAdded: _addCustomFixedExpenseCategory,
                onCustomCategoryRemoved: _removeCustomFixedExpenseCategory,
                onCustomCategoryAddedWithEmoji:
                    _addCustomFixedExpenseCategoryWithEmoji,
                categoryEmojis: _fixedExpenseCategoryEmojis,
              ),
            ),

          // 일 변동소비 모달
          if (_showDailySpendingModal)
            _buildAnimatedModal(
              animation: _dailySpendingBackgroundAnimation,
              slideAnimation: _dailySpendingModalAnimation,
              child: InputModalWidget(
                isOpen: _showDailySpendingModal,
                onClose: _closeDailySpendingModal,
                title: '하루 사용 금액',
                placeholder: '하루 소비 항목',
                hintText: '예: 식비, 교통비, 쇼핑 등',
                type: EntryType.daily,
                onCategorySettingsTap: _openDailyExpenseCategorySettings,
                onComplete: _updateDailySpendingData,
                customCategories: _customDailyExpenseCategories,
                onCustomCategoryAdded: _addCustomDailyExpenseCategory,
                onCustomCategoryRemoved: _removeCustomDailyExpenseCategory,
                onCustomCategoryAddedWithEmoji:
                    _addCustomDailyExpenseCategoryWithEmoji,
                categoryEmojis: _dailyExpenseCategoryEmojis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModalButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedModal({
    required Animation<double> animation,
    required Animation<Offset> slideAnimation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Material(
          color: Colors.black.withOpacity(animation.value * 0.5),
          child: SlideTransition(position: slideAnimation, child: child),
        );
      },
    );
  }
}

/// 카테고리 테스트 페이지를 열고 결과를 받는 함수
Future<void> openCategoryTestPage(BuildContext context) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (context) => const CategoryTestPage()));
}
