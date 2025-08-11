import 'package:flutter/material.dart';
import 'package:sotong_local/theme/app_colors.dart';
import 'package:sotong_local/theme/app_spacing.dart';
import 'package:sotong_local/component/texts/header_text.dart';
import 'package:sotong_local/component/texts/paragraph_text.dart';
import 'package:sotong_local/component/texts/subtext.dart';

class CommunicationLogsPage extends StatefulWidget {
  const CommunicationLogsPage({super.key});

  @override
  State<CommunicationLogsPage> createState() => _CommunicationLogsPageState();
}

class _CommunicationLogsPageState extends State<CommunicationLogsPage> {
  String _sortBy = 'date'; // 'date' 또는 'emotion'

  // 예시 데이터
  final List<Map<String, dynamic>> _logEntries = [
    {
      'date': DateTime(2025, 8, 1),
      'emotion': '😭',
      'emotionText': '슬픔',
      'amount': 13000,
      'note': '오늘 밥을 비싸게주고 먹었는데 맛이 없었다 슬프다',
      'isOverSpending': true,
    },
    {
      'date': DateTime(2025, 7, 22),
      'emotion': '😊',
      'emotionText': '기쁨',
      'amount': 30000,
      'note': 'ㅇㅇ',
      'isOverSpending': true,
    },
    {
      'date': DateTime(2025, 7, 11),
      'emotion': '😊',
      'emotionText': '기쁨',
      'amount': 13000,
      'note': '오늘 좋았다',
      'isOverSpending': false,
    },
    {
      'date': DateTime(2025, 7, 5),
      'emotion': '😤',
      'emotionText': '짜증',
      'amount': 15000,
      'note': '스트레스 받아서 쇼핑했어요',
      'isOverSpending': true,
    },
    {
      'date': DateTime(2025, 7, 1),
      'emotion': '😌',
      'emotionText': '평온',
      'amount': 8000,
      'note': '차분한 하루였어요',
      'isOverSpending': false,
    },
  ];

  List<Map<String, dynamic>> get _sortedEntries {
    List<Map<String, dynamic>> sorted = List.from(_logEntries);

    if (_sortBy == 'date') {
      sorted.sort((a, b) => b['date'].compareTo(a['date'])); // 최신순
    } else if (_sortBy == 'emotion') {
      sorted.sort((a, b) => a['emotionText'].compareTo(b['emotionText']));
    }

    return sorted;
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
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HeaderText(text: '소통 일지 모아보기'),
                  Row(
                    children: [
                      // 정렬 버튼
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sortBy == 'date'
                                  ? Icons.calendar_today
                                  : Icons.emoji_emotions,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sortBy == 'date' ? '날짜순' : '감정순',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _sortBy = _sortBy == 'date'
                                      ? 'emotion'
                                      : 'date';
                                });
                              },
                              child: const Icon(
                                Icons.swap_horiz,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 닫기 버튼
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 로그 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                itemCount: _sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = _sortedEntries[index];
                  return _buildLogEntry(entry);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final emotion = entry['emotion'] as String;
    final emotionText = entry['emotionText'] as String;
    final amount = entry['amount'] as int;
    final note = entry['note'] as String;
    final isOverSpending = entry['isOverSpending'] as bool;

    return GestureDetector(
      onTap: () {
        _showLogDetailDialog(entry);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 감정 이모지 (왼쪽)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(emotion, style: const TextStyle(fontSize: 24)),
              ),
            ),

            const SizedBox(width: 16),

            // 중앙 정보 (날짜, 금액, 노트)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  ParagraphText(
                    text: '${date.year}년 ${date.month}월 ${date.day}일',
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),

                  // 금액
                  Row(
                    children: [
                      ParagraphText(
                        text: '${_formatAmount(amount)}원 소비',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      // 상태 태그
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOverSpending ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOverSpending ? '초과 지출' : '적정 지출',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 노트
                  SubText(text: note, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogDetailDialog(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final emotion = entry['emotion'] as String;
    final emotionText = entry['emotionText'] as String;
    final amount = entry['amount'] as int;
    final note = entry['note'] as String;
    final isOverSpending = entry['isOverSpending'] as bool;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(emotion, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              emotionText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${date.year}년 ${date.month}월 ${date.day}일',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 소비 금액
            Row(
              children: [
                const Icon(Icons.attach_money, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '소비 금액',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${_formatAmount(amount)}원',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOverSpending ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOverSpending ? '초과 지출' : '적정 지출',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 소비 일지
            Row(
              children: [
                const Icon(Icons.note, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '소비 일지',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 수정 기능은 향후 구현
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
  }
}
