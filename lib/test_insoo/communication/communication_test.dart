import 'dart:async';
import 'package:flutter/material.dart';

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
  int selectedYear = DateTime.now().year;
  int _monthSlideDirection = 0;

  // 감정/금액 다이얼
  String selectedMode = '감정'; // '감정' 또는 '금액'
  late final PageController _modePageController;

  // 하루 소비 한도 금액
  final int dailySpendingLimit = 10000; // 10,000원

  // 감정별 소비 분석용
  String selectedEmotionForAnalysis = '기쁨'; // 분석할 감정 선택
  String selectedAnalysisPeriod = '주간';

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
    _modePageController = PageController(initialPage: 0);

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
    _modePageController.dispose();
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

  void _changeMode(String mode) {
    if (mode == selectedMode) return;
    setState(() {
      selectedMode = mode;
    });
    final targetIndex = mode == '감정' ? 0 : 1;
    _modePageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
                    _buildCalendarContainer(),
                    const SizedBox(height: 20),
                    _buildEmotionSpendingAnalysis(),
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

  Widget _buildCalendarContainer() {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    _buildAnalysisPeriodToggle(),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isEmotionDropdownOpen = !isEmotionDropdownOpen;
                          });
                        },
                        child: Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFE0E0E0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getEmotionEmojiForAnalysis(
                                  selectedEmotionForAnalysis,
                                ),
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedEmotionForAnalysis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isEmotionDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 20,
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _amountAnimation,
                        builder: (context, child) {
                          return Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatAmount(_amountAnimation.value.toInt()),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '원',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(height: isEmotionDropdownOpen ? 220 : 12),
              ],
            ),
            if (isEmotionDropdownOpen)
              Positioned(
                top: 92,
                left: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 165,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildNewDropdownOption('기쁨', isFirst: true),
                        _buildNewDropdownOption('혼란'),
                        _buildNewDropdownOption('슬픔'),
                        _buildNewDropdownOption('피곤'),
                        _buildNewDropdownOption('화남'),
                        _buildNewDropdownOption('플렉스', isLast: true),
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

  // 새로운 드롭다운 옵션 위젯
  Widget _buildNewDropdownOption(
    String emotion, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = selectedEmotionForAnalysis == emotion;
    return InkWell(
      onTap: () {
        setState(() {
          selectedEmotionForAnalysis = emotion;
          isEmotionDropdownOpen = false;
        });
        final newAmount = _getEmotionSpendingAmount(emotion);
        _animateAmount(newAmount);
      },
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isFirst ? 22 : 0),
        topRight: Radius.circular(isFirst ? 22 : 0),
        bottomLeft: Radius.circular(isLast ? 22 : 0),
        bottomRight: Radius.circular(isLast ? 22 : 0),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 22 : 0),
            topRight: Radius.circular(isFirst ? 22 : 0),
            bottomLeft: Radius.circular(isLast ? 22 : 0),
            bottomRight: Radius.circular(isLast ? 22 : 0),
          ),
          color: isSelected ? const Color(0xFFE9F2FF) : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : const Color(0xFFE5E5E8),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              emotion,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF0D6EFF) : Colors.black,
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0D6EFF)
                      : const Color(0xFFD3D3D6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0D6EFF),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisPeriodToggle() {
    const periods = ['주간', '월간'];
    final selectedIndex = periods.indexOf(selectedAnalysisPeriod);

    Alignment _alignmentForIndex(int index) {
      switch (index) {
        case 0:
          return Alignment.centerLeft;
        case 1:
          return Alignment.centerRight;
        default:
          return Alignment.centerLeft;
      }
    }

    return Container(
      width: 100,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: _alignmentForIndex(selectedIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: List.generate(periods.length, (index) {
              final period = periods[index];
              final isSelected = selectedAnalysisPeriod == period;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _changeAnalysisPeriod(period),
                  child: Center(
                    child: Text(
                      period,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _changeAnalysisPeriod(String period) {
    if (selectedAnalysisPeriod == period) return;
    setState(() {
      selectedAnalysisPeriod = period;
    });
    _animateAmount(_getEmotionSpendingAmount(selectedEmotionForAnalysis));
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final mediaQuery = MediaQuery.of(context);
        final maxHeight = mediaQuery.size.height * 0.8;

        final content = hasRecord
            ? _buildRecordedDateContent(day)
            : _buildEmptyDateContent(day);

        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Padding(
            padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      content,
                    ],
                  ),
                ),
              ),
            ),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$selectedMonth월 ${day}일',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          '소비를 기록해주세요',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '소비입력하러 가기',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedYear}년',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  width: 100,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        alignment: selectedMode == '감정'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 3,
                          ),
                          child: Container(
                            width: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _changeMode('감정'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  '감정',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedMode == '감정'
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _changeMode('금액'),
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: Text(
                                  '금액',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selectedMode == '금액'
                                        ? Colors.black87
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
    final firstDayOfMonth = DateTime(selectedYear, selectedMonth, 1);
    final lastDayOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return Container(
      padding: const EdgeInsets.all(16),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final key = child.key;
          final isIncoming = key is ValueKey<int> && key.value == selectedMonth;

          final incomingOffset = _monthSlideDirection == 1
              ? const Offset(0, 1)
              : _monthSlideDirection == -1
              ? const Offset(0, -1)
              : Offset.zero;
          final outgoingOffset = _monthSlideDirection == 1
              ? const Offset(0, -1)
              : _monthSlideDirection == -1
              ? const Offset(0, 1)
              : Offset.zero;

          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          final Animation<Offset> slideAnimation = isIncoming
              ? Tween<Offset>(
                  begin: incomingOffset,
                  end: Offset.zero,
                ).animate(curved)
              : Tween<Offset>(
                  begin: Offset.zero,
                  end: outgoingOffset,
                ).animate(ReverseAnimation(curved));

          return ClipRect(
            child: SlideTransition(position: slideAnimation, child: child),
          );
        },
        child: Column(
          key: ValueKey<int>(selectedMonth),
          children: [
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
            LayoutBuilder(
              builder: (context, constraints) {
                final cellSize = constraints.maxWidth / 7;
                final estimatedHeight = cellSize * 6 + 16;

                return SizedBox(
                  height: estimatedHeight,
                  child: PageView(
                    controller: _modePageController,
                    physics: const ClampingScrollPhysics(),
                    onPageChanged: (index) {
                      final mode = index == 0 ? '감정' : '금액';
                      if (mode != selectedMode) {
                        setState(() {
                          selectedMode = mode;
                        });
                      }
                    },
                    children: [
                      _buildCalendarGrid(
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: true,
                      ),
                      _buildCalendarGrid(
                        firstWeekday: firstWeekday,
                        daysInMonth: daysInMonth,
                        showEmotion: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid({
    required int firstWeekday,
    required int daysInMonth,
    required bool showEmotion,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - firstWeekday + 1;
        final isCurrentMonth = day > 0 && day <= daysInMonth;

        if (!isCurrentMonth) {
          return const SizedBox();
        }

        final selectedDate = DateTime(selectedYear, selectedMonth, day);
        final bool isRecordedMonth =
            selectedYear == DateTime.now().year && selectedMonth == 10;
        final hasEmotion = isRecordedMonth && _getEmotionEmoji(day).isNotEmpty;
        final hasAmount = isRecordedMonth && _getSpendingAmount(day) > 0;
        final hasRecord = hasEmotion || hasAmount;

        return GestureDetector(
          onTap: () {
            _showDateDetailModal(day, hasRecord);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRecordedMonth && showEmotion && hasEmotion)
                    const SizedBox(height: 2),
                  Text(
                    '$day',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (isRecordedMonth && showEmotion && hasEmotion)
                    Text(
                      _getEmotionEmoji(day),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    )
                  else if (isRecordedMonth && !showEmotion && hasAmount)
                    Text(
                      '${_getSpendingAmount(day)}원',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getSpendingAmount(day) > dailySpendingLimit
                            ? Colors.red
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
                _monthSlideDirection = -1;
                selectedMonth--;
                if (selectedMonth < 1) {
                  selectedMonth = 12;
                  selectedYear--;
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
                _monthSlideDirection = 1;
                selectedMonth++;
                if (selectedMonth > 12) {
                  selectedMonth = 1; // 1월로 순환
                  selectedYear++;
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
