import 'package:flutter/material.dart';
import 'dart:async';

import '../../../component/texts/subtext.dart';
import '../../../component/theme/app_colors.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool isWeekly = true; // 주간/월간 토글
  int currentInsightIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  // 소비 인사이트 데이터 (무한 스크롤을 위해 반복)
  late List<Map<String, dynamic>> insights;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 원본 데이터
    final originalInsights = [
      {
        'title': '주말 소비 증가',
        'description': '주말에 평일 대비 40% 더 많은 지출이 발생했어요',
        'icon': Icons.trending_up,
        'color': Colors.red,
      },
      {
        'title': '식비 절약 성공',
        'description': '이번 주 식비가 지난 주 대비 15% 줄었어요',
        'icon': Icons.trending_down,
        'color': Colors.green,
      },
      {
        'title': '교통비 초과 경고',
        'description': '이번 주 교통비 지출이 한도보다 20% 초과했어요',
        'icon': Icons.warning,
        'color': Colors.orange,
      },
    ];

    // 무한 스크롤을 위해 데이터를 여러 번 반복
    insights = [];
    for (int i = 0; i < 10; i++) {
      insights.addAll(originalInsights);
    }

    _startAutoSlide();
  }

  // 주간 카테고리별 소비 데이터
  final List<Map<String, dynamic>> weeklyCategorySpending = [
    {
      'category': '식비',
      'amount': 30000,
      'percentage': 40,
      'color': AppColors.primary,
    },
    {
      'category': '교통비',
      'amount': 12500,
      'percentage': 17,
      'color': AppColors.primary,
    },
    {
      'category': '고정비',
      'amount': 20000,
      'percentage': 27,
      'color': AppColors.primary,
    },
    {
      'category': '기타',
      'amount': 12500,
      'percentage': 16,
      'color': AppColors.primary,
    },
  ];

  // 월간 카테고리별 소비 데이터
  final List<Map<String, dynamic>> monthlyCategorySpending = [
    {
      'category': '식비',
      'amount': 120000,
      'percentage': 35,
      'color': AppColors.primary,
    },
    {
      'category': '교통비',
      'amount': 45000,
      'percentage': 13,
      'color': AppColors.primary,
    },
    {
      'category': '고정비',
      'amount': 80000,
      'percentage': 23,
      'color': AppColors.primary,
    },
    {
      'category': '기타',
      'amount': 45000,
      'percentage': 13,
      'color': AppColors.primary,
    },
    {
      'category': '문화생활',
      'amount': 55000,
      'percentage': 16,
      'color': AppColors.primary,
    },
  ];

  // 주간 소비 트렌드 데이터
  final List<Map<String, dynamic>> weeklyTrend = [
    {'day': '월', 'amount': 8000, 'isOverTarget': true},
    {'day': '화', 'amount': 6500, 'isOverTarget': false},
    {'day': '수', 'amount': 7200, 'isOverTarget': true},
    {'day': '목', 'amount': 5800, 'isOverTarget': false},
    {'day': '금', 'amount': 9100, 'isOverTarget': true},
    {'day': '토', 'amount': 12000, 'isOverTarget': true},
    {'day': '일', 'amount': 4500, 'isOverTarget': false},
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (currentInsightIndex + 1) % insights.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
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
                        '소비 리포트',
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
                    // 예상 목표 도달일 카드 (중앙 정렬)
                    Center(child: _buildGoalAchievementCard()),
                    const SizedBox(height: 24),

                    // 소비 인사이트 카드
                    _buildInsightsCard(),
                    const SizedBox(height: 24),

                    // 카테고리별 소비
                    _buildCategorySpendingCard(),
                    const SizedBox(height: 24),

                    // 주간 소비 트렌드
                    _buildWeeklyTrendCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalAchievementCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '예상 목표 도달일',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '2024년 8월 15일',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '현재보다 3일 지연 중',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '현재 소비 패턴으로 계산된 예상 날짜입니다',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsCard() {
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
            '소비 인사이트',
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
              itemCount: insights.length,
              itemBuilder: (context, index) {
                final insight = insights[index];
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
                            SubText(text: '${insight['description']}'),
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

  Widget _buildCategorySpendingCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.pie_chart,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '카테고리별 소비',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // 토글 스위치
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isWeekly = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isWeekly
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '주간',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isWeekly ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isWeekly = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !isWeekly
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '월간',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: !isWeekly ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...(isWeekly ? weeklyCategorySpending : monthlyCategorySpending).map((
            category,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      category['category'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: category['percentage'] / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: category['color'],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_formatAmount(category['amount'])}원 (${category['percentage']}%)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendCard() {
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
            '주간 소비 트렌드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weeklyTrend.map((day) {
              final maxAmount = weeklyTrend
                  .map((d) => d['amount'] as int)
                  .reduce((a, b) => a > b ? a : b);
              final containerHeight = 120.0;
              final fillHeight = (day['amount'] / maxAmount) * containerHeight;

              return Column(
                children: [
                  Text(
                    day['day'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 24,
                    height: containerHeight,
                    decoration: BoxDecoration(
                      color: day['isOverTarget']
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: containerHeight - fillHeight),
                        Container(
                          width: 24,
                          height: fillHeight,
                          decoration: BoxDecoration(
                            color: day['isOverTarget']
                                ? Colors.red
                                : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatAmount(day['amount'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
