import 'dart:async';
import 'package:flutter/material.dart';

import 'package:sotong_local/component/theme/app_colors.dart';

class CommunicationTestPage extends StatefulWidget {
  const CommunicationTestPage({super.key});

  @override
  State<CommunicationTestPage> createState() => _CommunicationTestPageState();
}

class _CommunicationTestPageState extends State<CommunicationTestPage>
    with SingleTickerProviderStateMixin {
  // 소통 인사이트 (앱바용)
  late final List<Map<String, dynamic>> communicationInsights;
  int currentCommunicationIndex = 0;
  late PageController _communicationPageController;
  Timer? _communicationTimer;

  // 월 선택
  int selectedMonth = 10; // 10월부터 시작

  // 감정/금액 다이얼
  String selectedMode = '감정'; // '감정' 또는 '금액'

  // 하루 소비 한도 금액
  final int dailySpendingLimit = 10000; // 10,000원

  // 감정별 소비 분석용
  String selectedEmotionForAnalysis = '기쁨'; // 분석할 감정 선택
  String selectedPeriod = '이번 달'; // 기간 선택

  // 드롭다운 상태 관리
  bool isEmotionDropdownOpen = false;

  // 숫자 애니메이션 관련
  late AnimationController _amountAnimationController;
  late Animation<double> _amountAnimation;
  int _previousAmount = 45000;
  int _currentAmount = 45000;

  @override
  void initState() {
    super.initState();
    _communicationPageController = PageController();

    // 숫자 애니메이션 컨트롤러 초기화
    _amountAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _amountAnimation =
        Tween<double>(
          begin: _previousAmount.toDouble(),
          end: _currentAmount.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _amountAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 소통 인사이트 데이터 (앱바용)
    final originalCommunicationInsights = [
      {
        'title': '행복할 때 소비가 30% 증가해요',
        'icon': Icons.mood,
        'color': const Color(0xFF4CAF50), // 초록색 (긍정적)
      },
      {
        'title': '우울할 때 외식 지출이 50% 늘어나요',
        'icon': Icons.restaurant,
        'color': const Color(0xFFE57373), // 빨간색 (주의)
      },
      {
        'title': '화날 때 쇼핑 지출이 40% 증가해요',
        'icon': Icons.shopping_bag,
        'color': const Color(0xFFFF8F00), // 오렌지색 (경고)
      },
      {
        'title': '피곤할 때 편의점 이용이 늘어나요',
        'icon': Icons.local_convenience_store,
        'color': const Color(0xFF9E9E9E), // 회색 (중립)
      },
      {
        'title': '기쁠 때 카페 지출이 증가해요',
        'icon': Icons.local_cafe,
        'color': const Color(0xFF8BC34A), // 연한 초록색
      },
      {
        'title': '스트레스 받을 때 온라인 쇼핑이 늘어나요',
        'icon': Icons.shopping_cart,
        'color': const Color(0xFFF44336), // 빨간색 (경고)
      },
      {
        'title': '감정 변화가 소비 패턴에 큰 영향을 미쳐요',
        'icon': Icons.psychology,
        'color': const Color(0xFF3F51B5), // 파란색 (정보)
      },
    ];

    communicationInsights = [];
    for (int i = 0; i < 10; i++) {
      communicationInsights.addAll(originalCommunicationInsights);
    }

    _startCommunicationAutoSlide();
  }

  @override
  void dispose() {
    _communicationTimer?.cancel();
    _communicationPageController.dispose();
    _amountAnimationController.dispose();
    super.dispose();
  }

  void _startCommunicationAutoSlide() {
    _communicationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_communicationPageController.hasClients) {
        final nextPage =
            (currentCommunicationIndex + 1) % communicationInsights.length;
        _communicationPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // 금액 애니메이션 실행
  void _animateAmount(int newAmount) {
    setState(() {
      _previousAmount = _currentAmount;
      _currentAmount = newAmount;

      _amountAnimation =
          Tween<double>(
            begin: _previousAmount.toDouble(),
            end: _currentAmount.toDouble(),
          ).animate(
            CurvedAnimation(
              parent: _amountAnimationController,
              curve: Curves.easeOutCubic,
            ),
          );

      _amountAnimationController.reset();
      _amountAnimationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 앱바에 소통 인사이트 (공지사항 스타일)
            _buildAppBarWithInsights(),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCalendarAndLogsContainer(),
                    const SizedBox(height: 20),
                    _buildMonthlyEmotionSummaryWidget(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 앱바에 소통 인사이트 (공지사항 스타일)
  Widget _buildAppBarWithInsights() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        height: 44,
        child: PageView.builder(
          controller: _communicationPageController,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) {
            setState(() {
              currentCommunicationIndex = index;
            });
          },
          itemCount: communicationInsights.length,
          itemBuilder: (context, index) {
            final insight = communicationInsights[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: insight['color'].withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: insight['color'].withOpacity(0.25),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(insight['icon'], color: insight['color'], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarAndLogsContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 선택 다이얼
          _buildMonthSelector(),
          const SizedBox(height: 16),

          // 달력과 모드 다이얼 컨테이너
          _buildCalendarWithModeDials(),
          const SizedBox(height: 16),

          // 감정별 소비 분석 컨테이너
          _buildEmotionSpendingAnalysis(),
          const SizedBox(height: 16),

          // 소통일지 모아보기 링크
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('테스트 페이지에서는 이동할 수 없습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.insights, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '소통 일지 모아보기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '감정과 소비 패턴을 한눈에 확인해보세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyEmotionSummaryWidget() {
    // 테스트용 하드코딩된 데이터
    final happyCount = 8;
    final normalCount = 12;
    final gloomyCount = 5;
    final overallMessage = '긍정적인 한 달을 보내고 계시네요';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 감정 요약',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // 감정 카드들
          Row(
            children: [
              // 행복한 날 카드
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FAE6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('😊', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        '행복한 날',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$happyCount일',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 평범한 날 카드
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('😐', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        '평범한 날',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$normalCount일',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 우울한 날 카드
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6E6),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('😢', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text(
                        '우울한 날',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$gloomyCount일',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE57373),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 결론 메시지
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
            child: Text(
              overallMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 감정별 소비 분석 컨테이너
  Widget _buildEmotionSpendingAnalysis() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (제목 + 기간 선택)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '감정별 소비 분석',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // 기간 선택 버튼
                GestureDetector(
                  onTap: () {
                    _showPeriodSelector();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedPeriod,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 감정 선택 및 금액 표시 (1개 감정 + 금액)
            Row(
              children: [
                // 감정 선택 버튼 (드롭다운)
                SizedBox(
                  width: 120,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isEmotionDropdownOpen = !isEmotionDropdownOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getEmotionEmojiForAnalysis(
                              selectedEmotionForAnalysis,
                            ),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              selectedEmotionForAnalysis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            isEmotionDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // 금액 표시 - 중앙 정렬, 천 단위 구분자, 애니메이션
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _amountAnimation,
                      builder: (context, child) {
                        return Text(
                          '${_formatAmount(_amountAnimation.value.toInt())}원',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // 드롭다운 감정 리스트 - 새로운 방식
            if (isEmotionDropdownOpen)
              Container(
                width: 120,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildNewDropdownOption('기쁨', '😊'),
                    _buildNewDropdownOption('혼란', '😵‍💫'),
                    _buildNewDropdownOption('슬픔', '😢'),
                    _buildNewDropdownOption('피곤', '😴'),
                    _buildNewDropdownOption('화남', '😠'),
                    _buildNewDropdownOption('플렉스', '😎'),
                  ],
                ),
              ),

            // 평균 소비 텍스트
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${selectedEmotionForAnalysis}이 선택된 날엔 평균적으로 ${_formatAmount(_getEmotionSpendingAmount(selectedEmotionForAnalysis))}원만큼 소비해요.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 새로운 드롭다운 옵션 위젯
  Widget _buildNewDropdownOption(String emotion, String emoji) {
    final isSelected = selectedEmotionForAnalysis == emotion;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedEmotionForAnalysis = emotion;
          isEmotionDropdownOpen = false;
        });
        // 새 감정의 금액으로 애니메이션 실행
        int newAmount = _getEmotionSpendingAmount(emotion);
        _animateAmount(newAmount);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              emotion,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 천 단위 구분자 포맷 함수
  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }

  // 날짜 상세 모달 표시
  void _showDateDetailModal(int day, bool hasRecord) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: hasRecord
              ? _buildRecordedDateContent(day)
              : _buildEmptyDateContent(day),
        );
      },
    );
  }

  // 기록된 날짜 내용
  Widget _buildRecordedDateContent(int day) {
    final emotion = _getEmotionEmoji(day);
    final amount = _getSpendingAmount(day);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (날짜 + 수정 버튼)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$selectedMonth월 ${day}일',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 수정 페이지로 이동 (추후 구현)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수정 기능은 추후 구현됩니다')),
                );
              },
              icon: const Icon(Icons.edit, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 감정 정보
        if (emotion.isNotEmpty) ...[
          Row(
            children: [
              Text(emotion, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _getEmotionNameFromEmoji(emotion),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // 소비 목록 (실제 금액과 일치하도록 수정)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '소비 목록',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildSpendingItem('식비', (amount * 0.6).round()),
              _buildSpendingItem('교통비', (amount * 0.2).round()),
              _buildSpendingItem('카페', (amount * 0.2).round()),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '총 합산',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_formatAmount(amount)}원',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 소비 일지 (하드코딩된 예시)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '소비 일지',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '오늘은 맛있는 점심을 먹었어요. 친구와 함께 카페에서 시간을 보냈습니다.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 빈 날짜 내용
  Widget _buildEmptyDateContent(int day) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$selectedMonth월 ${day}일',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const Text(
          '소비를 기록해주세요',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // 소비 입력 페이지로 이동 (추후 구현)
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('소비 입력 페이지로 이동합니다')));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('소비입력하러 가기'),
        ),
      ],
    );
  }

  // 소비 항목 위젯
  Widget _buildSpendingItem(String category, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category, style: const TextStyle(fontSize: 13)),
          Text(
            '${_formatAmount(amount)}원',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  // 이모지에서 감정 이름 가져오기
  String _getEmotionNameFromEmoji(String emoji) {
    switch (emoji) {
      case '😊':
        return '기쁨';
      case '😵‍💫':
        return '혼란';
      case '😢':
        return '슬픔';
      case '😴':
        return '피곤';
      case '😠':
        return '화남';
      case '😎':
        return '플렉스';
      default:
        return '알 수 없음';
    }
  }

  // 기간 선택 다이얼로그
  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '기간 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption('이번 주'),
              _buildPeriodOption('이번 달'),
              _buildPeriodOption('지난 달'),
              _buildPeriodOption('최근 3개월'),
            ],
          ),
        );
      },
    );
  }

  // 기간 옵션 위젯
  Widget _buildPeriodOption(String period) {
    return ListTile(
      title: Text(period),
      onTap: () {
        setState(() {
          selectedPeriod = period;
        });
        Navigator.of(context).pop();
      },
    );
  }

  // 감정별 이모지 반환
  String _getEmotionEmojiForAnalysis(String emotion) {
    switch (emotion) {
      case '기쁨':
        return '😊';
      case '혼란':
        return '😵‍💫';
      case '슬픔':
        return '😢';
      case '피곤':
        return '😴';
      case '화남':
        return '😠';
      case '플렉스':
        return '😎';
      default:
        return '😐';
    }
  }

  // 감정별 소비 금액 계산
  int _getEmotionSpendingAmount(String emotion) {
    // 감정별 소비 금액 데이터 (테스트용)
    final emotionSpendingData = {
      '기쁨': 45000,
      '혼란': 28000,
      '슬픔': 52000,
      '피곤': 35000,
      '화남': 68000,
      '플렉스': 42000,
    };

    return emotionSpendingData[emotion] ?? 0;
  }

  // 달력과 모드 다이얼 컨테이너
  Widget _buildCalendarWithModeDials() {
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
          // 상단: 모드 다이얼 (On/Off 스위치 스타일)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 감정 버튼
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMode = '감정';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedMode == '감정'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: selectedMode == '감정'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '감정',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedMode == '감정'
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      // 금액 버튼
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedMode = '금액';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selectedMode == '금액'
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: selectedMode == '금액'
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            '금액',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: selectedMode == '금액'
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 달력
          _buildCalendar(),
        ],
      ),
    );
  }

  // 달력 위젯
  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, selectedMonth, 1);
    final lastDayOfMonth = DateTime(now.year, selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6주 * 7일
            itemBuilder: (context, index) {
              final day = index - firstWeekday + 1;
              final isCurrentMonth = day > 0 && day <= daysInMonth;

              if (!isCurrentMonth) {
                return const SizedBox();
              }

              return GestureDetector(
                onTap: () {
                  // 날짜 클릭 시 팝업 모달 표시
                  final hasEmotion = _getEmotionEmoji(day).isNotEmpty;
                  final hasAmount = _getSpendingAmount(day) > 0;
                  final hasRecord = hasEmotion || hasAmount;
                  _showDateDetailModal(day, hasRecord);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.transparent, // 오늘 날짜 하이라이트 제거
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: _getEmotionEmoji(day).isEmpty ? 16 : 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        // 모드에 따라 다른 내용 표시 (10월 27일까지)
                        if (selectedMonth == 10 &&
                            day <= 27 &&
                            _getEmotionEmoji(day).isNotEmpty)
                          selectedMode == '감정'
                              ? Text(
                                  _getEmotionEmoji(day),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                )
                              : Text(
                                  '${_getSpendingAmount(day)}원',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        _getSpendingAmount(day) >
                                            dailySpendingLimit
                                        ? Colors.red
                                        : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 감정 이모지 반환 메서드
  String _getEmotionEmoji(int day) {
    // 이모지가 없는 날짜들 (랜덤으로 선택된 5일)
    final noEmojiDays = [3, 7, 14, 19, 23];

    // 이모지가 없는 날짜면 빈 문자열 반환
    if (noEmojiDays.contains(day)) {
      return '';
    }

    // 특정 날짜에 특정 이모지 할당
    switch (day) {
      case 1:
        return '😊'; // 기쁨
      case 2:
        return '😵‍💫'; // 혼란
      case 4:
        return '😴'; // 피곤
      case 5:
        return '😠'; // 화남
      case 6:
        return '😎'; // 플렉스
      case 8:
        return '😵‍💫'; // 혼란
      case 9:
        return '😢'; // 슬픔
      case 10:
        return '😴'; // 피곤
      case 11:
        return '😠'; // 화남
      case 12:
        return '😎'; // 플렉스
      case 13:
        return '😊'; // 기쁨
      case 15:
        return '😢'; // 슬픔
      case 16:
        return '😴'; // 피곤
      case 17:
        return '😠'; // 화남
      case 18:
        return '😎'; // 플렉스
      case 20:
        return '😵‍💫'; // 혼란
      case 21:
        return '😢'; // 슬픔
      case 22:
        return '😴'; // 피곤
      case 24:
        return '😎'; // 플렉스
      case 25:
        return '😊'; // 기쁨
      case 26:
        return '😎'; // 플렉스 (요청사항)
      case 27:
        return '😵‍💫'; // 혼란
      default:
        return '';
    }
  }

  // 금액 데이터 반환 메서드
  int _getSpendingAmount(int day) {
    // 이모지가 없는 날짜들 (감정 기록이 없는 날)
    final noEmojiDays = [3, 7, 14, 19, 23];

    // 감정 기록이 없는 날이면 금액도 0
    if (noEmojiDays.contains(day)) {
      return 0;
    }

    // 랜덤 금액 생성 (1,000원 ~ 10,000원)
    final randomAmounts = {
      1: 8500,
      2: 3200,
      4: 12000,
      5: 5600,
      6: 7800,
      8: 4500,
      9: 9200,
      10: 6800,
      11: 15000,
      12: 4200,
      13: 8800,
      15: 7300,
      16: 5100,
      17: 9600,
      18: 3400,
      20: 8200,
      21: 6700,
      22: 4900,
      24: 8900,
      25: 7500,
      26: 11000,
      27: 5800,
    };

    return randomAmounts[day] ?? 0;
  }

  // 월 선택 다이얼
  Widget _buildMonthSelector() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 왼쪽 화살표 (이전 달)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedMonth--;
                if (selectedMonth < 1) {
                  selectedMonth = 12; // 12월로 순환
                }
              });
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

          // 중앙 월 표시
          Text(
            '$selectedMonth월',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(width: 8),

          // 오른쪽 화살표 (다음 달)
          GestureDetector(
            onTap: () {
              setState(() {
                selectedMonth++;
                if (selectedMonth > 12) {
                  selectedMonth = 1; // 1월로 순환
                }
              });
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
    );
  }
}
