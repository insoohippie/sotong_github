import 'package:flutter/material.dart';
import 'package:sotong_local/component/texts/header_text.dart';

import '../../../component/texts/subtext.dart';
import '../../../component/theme/app_spacing.dart';

class CommunicationInsightPage extends StatelessWidget {
  const CommunicationInsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const HeaderText(text: '소통 인사이트'),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 소통 인사이트 섹션
                    _buildInsightSection(),
                    const SizedBox(height: 24),

                    // 감정 소비 트렌드 섹션
                    _buildTrendSection(),
                    const SizedBox(height: 24),

                    // 이번 달 감정 요약 섹션
                    _buildEmotionSummarySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.blue[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                '소통 인사이트',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 감정 소비 패턴
          _buildInsightItem(
            icon: Icons.trending_up,
            iconColor: Colors.blue,
            title: '감정 소비 패턴',
            description: '행복할 때 0원 더 많이 소비하는 경향이 있어요.',
          ),
          const SizedBox(height: 16),

          // 소비 카테고리 분석
          _buildInsightItem(
            icon: Icons.trending_down,
            iconColor: Colors.green,
            title: '소비 카테고리 분석',
            description: '배달음식과 쇼핑을 할 때 감정이 안좋아지는 경향이 있어요. 대신 산책이나 독서를 해보세요!',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              SubText(text: '${description}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.favorite_border, color: Colors.blue[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                '감정 소비 트렌드',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 우울한 날 평균 소비
          _buildTrendItem(
            emoji: '😢',
            title: '우울한 날 평균 소비',
            amount: '13,000원',
            color: Colors.red,
            backgroundColor: Colors.red[50]!,
          ),
          const SizedBox(height: 12),

          // 행복한 날 평균 소비
          _buildTrendItem(
            emoji: '😊',
            title: '행복한 날 평균 소비',
            amount: '13,000원',
            color: Colors.green,
            backgroundColor: Colors.green[50]!,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem({
    required String emoji,
    required String title,
    required String amount,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
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
              Expanded(
                child: _buildEmotionCard(
                  emoji: '😊',
                  title: '행복한 날',
                  days: '1일',
                  color: Colors.green,
                  backgroundColor: Colors.green[50]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmotionCard(
                  emoji: '😐',
                  title: '평범한 날',
                  days: '0일',
                  color: Colors.grey,
                  backgroundColor: Colors.grey[50]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEmotionCard(
                  emoji: '😢',
                  title: '우울한 날',
                  days: '1일',
                  color: Colors.red,
                  backgroundColor: Colors.red[50]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 결론 메시지
          Center(
            child: const Text(
              '긍정적인 한 달을 보내고 계시네요',
              style: TextStyle(
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

  Widget _buildEmotionCard({
    required String emoji,
    required String title,
    required String days,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            days,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
