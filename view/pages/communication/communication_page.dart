import 'package:flutter/material.dart';
import 'package:sotong_local/view/pages/record/record_widgets/emotion_calendar_widget.dart';
import 'package:sotong_local/model/emotion_spending_diary.dart';
import 'package:sotong_local/view/pages/communication/communication_logs_page.dart';
import 'package:sotong_local/view_model/communication/communication_view_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../component/theme/app_colors.dart';
import '../record/record_widgets/emotion_diary_detail_dialog.dart';
import '../record/record_widgets/spending_record_confirm_dialog.dart'; // Added for Timer

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  // CommunicationViewModel에서 데이터를 가져옴

  // 감정 소비 패턴 데이터 (무한 스크롤을 위해 반복)
  late List<Map<String, dynamic>> emotionInsights;
  int currentInsightIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 원본 데이터
    final originalInsights = [
      {
        'title': '행복할 때 소비 증가',
        'description': '행복한 감정일 때 평균 30% 더 많은 지출이 발생했어요',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
      {
        'title': '우울할 때 외식 증가',
        'description': '우울한 감정일 때 외식 지출이 50% 증가했어요',
        'icon': Icons.restaurant,
        'color': Colors.orange,
      },
      {
        'title': '화날 때 쇼핑 증가',
        'description': '화난 감정일 때 쇼핑 지출이 40% 증가했어요',
        'icon': Icons.shopping_bag,
        'color': Colors.red,
      },
    ];

    // 무한 스크롤을 위해 데이터를 여러 번 반복
    emotionInsights = [];
    for (int i = 0; i < 10; i++) {
      emotionInsights.addAll(originalInsights);
    }

    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (currentInsightIndex + 1) % emotionInsights.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleDateTapped(DateTime date) {
    final communicationViewModel = context.read<CommunicationViewModel>();
    final entry = communicationViewModel.diaryEntries.firstWhere(
      (entry) =>
          entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day,
      orElse: () => EmotionSpendingDiary(
        date: date,
        emotion: '',
        emotionAnimation: '',
        spendingAmount: 0,
        spendingDescription: '',
        memo: '',
      ),
    );

    if (entry.emotion.isNotEmpty) {
      // 기록된 날짜 - 상세 정보 표시
      _showDiaryDetailDialog(entry);
    } else {
      // 기록되지 않은 날짜 - 소비 기록 확인
      _showSpendingRecordDialog(date);
    }
  }

  void _showDiaryDetailDialog(EmotionSpendingDiary entry) {
    showDialog(
      context: context,
      builder: (context) =>
          EmotionDiaryDetailDialog(diary: entry, selectedDate: entry.date),
    );
  }

  void _showSpendingRecordDialog(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => SpendingRecordConfirmDialog(
        selectedDate: date,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/record_spending');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '소통일지',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 감정 달력과 소통일지 모아보기 공유 컨테이너
                    _buildCalendarAndLogsContainer(),
                    const SizedBox(height: 20),

                    // 감정 소비 패턴 위젯 (레포트 스타일)
                    _buildEmotionSpendingPatternWidget(),
                    const SizedBox(height: 20),

                    // 감정 소비 트렌드 위젯
                    _buildEmotionSpendingTrendWidget(),
                    const SizedBox(height: 20),

                    // 이번 달 감정 요약 위젯
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '감정 달력',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 달력 위젯
          SizedBox(
            height: 385,
            child: Consumer<CommunicationViewModel>(
              builder: (context, communicationViewModel, child) {
                print(
                  '달력 업데이트: ${communicationViewModel.diaryEntries.length}개 데이터',
                );
                return EmotionCalendarWidget(
                  diaryEntries: communicationViewModel.diaryEntriesMap,
                  onDateSelected: (date) {},
                  onDateTapped: _handleDateTapped,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // 소통일지 모아보기 링크
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunicationLogsPage(),
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

  Widget _buildEmotionSpendingPatternWidget() {
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
            '감정 소비 패턴',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 100,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: (index) {
                setState(() {
                  currentInsightIndex = index;
                });
              },
              itemCount: emotionInsights.length,
              itemBuilder: (context, index) {
                final insight = emotionInsights[index];
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                      Icon(insight['icon'], color: insight['color'], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              insight['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSpendingTrendWidget() {
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '감정 소비 트렌드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이번 주 감정 안정성 향상',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '지난 주 대비 감정 변화가 15% 줄어들었어요',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
  }

  Widget _buildMonthlyEmotionSummaryWidget() {
    return Consumer<CommunicationViewModel>(
      builder: (context, communicationViewModel, child) {
        // 이번 달 감정 데이터 분석
        final currentMonth = DateTime.now().month;
        final currentYear = DateTime.now().year;

        final monthlyEntries = communicationViewModel.diaryEntries
            .where(
              (entry) =>
                  entry.date.year == currentYear &&
                  entry.date.month == currentMonth,
            )
            .toList();

        // 감정별 카운트
        final happyCount = monthlyEntries
            .where(
              (e) =>
                  e.emotion == '기쁨' || e.emotion == '행복' || e.emotion == '플렉스',
            )
            .length;
        final normalCount = monthlyEntries
            .where((e) => e.emotion == '혼란' || e.emotion == '피곤')
            .length;
        final gloomyCount = monthlyEntries
            .where(
              (e) =>
                  e.emotion == '슬픔' || e.emotion == '우울' || e.emotion == '화남',
            )
            .length;

        // 전체 감정 평가
        String overallMessage = '';
        if (happyCount > gloomyCount && happyCount > normalCount) {
          overallMessage = '긍정적인 한 달을 보내고 계시네요';
        } else if (gloomyCount > happyCount && gloomyCount > normalCount) {
          overallMessage = '조금 힘든 한 달이었네요. 힘내세요!';
        } else {
          overallMessage = '안정적인 한 달을 보내고 계시네요';
        }

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
                        color: const Color(0xFFE6FAE6), // 연한 초록색
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
                            '${happyCount}일',
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
                        color: const Color(0xFFF8F8F8), // 연한 회색
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
                            '${normalCount}일',
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
                        color: const Color(0xFFFFE6E6), // 연한 빨간색
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
                            '${gloomyCount}일',
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
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
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
      },
    );
  }
}
