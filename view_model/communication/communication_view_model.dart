import 'package:flutter/material.dart';
import '../../model/emotion_spending_diary.dart';

class CommunicationViewModel extends ChangeNotifier {
  List<EmotionSpendingDiary> _diaryEntries = [
    // 오늘
    EmotionSpendingDiary(
      date: DateTime.now(),
      emotion: '기쁨',
      emotionAnimation: 'assets/animations/Great.json',
      spendingAmount: 25000,
      spendingDescription: '점심 식사',
      memo: '맛있는 라면을 먹었다',
    ),
    // 어제
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 1)),
      emotion: '슬픔',
      emotionAnimation: 'assets/animations/UU.json',
      spendingAmount: 50000,
      spendingDescription: '쇼핑',
      memo: '불필요한 지출이 많았다',
    ),
    // 3일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 3)),
      emotion: '화남',
      emotionAnimation: 'assets/animations/Verify.json',
      spendingAmount: 8000,
      spendingDescription: '교통비',
      memo: '버스가 늦어서 화가 났다',
    ),
    // 5일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 5)),
      emotion: '평온',
      emotionAnimation: 'assets/animations/Done.json',
      spendingAmount: 15000,
      spendingDescription: '영화 관람',
      memo: '오랜만에 영화를 봤다',
    ),
    // 7일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 7)),
      emotion: '기쁨',
      emotionAnimation: 'assets/animations/Great.json',
      spendingAmount: 30000,
      spendingDescription: '외식',
      memo: '친구들과 맛있는 저녁을 먹었다',
    ),
    // 10일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 10)),
      emotion: '혼란',
      emotionAnimation: 'assets/animations/Loading.json',
      spendingAmount: 12000,
      spendingDescription: '커피',
      memo: '기분이 안 좋아서 커피를 마셨다',
    ),
    // 12일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 12)),
      emotion: '만족',
      emotionAnimation: 'assets/animations/Done.json',
      spendingAmount: 18000,
      spendingDescription: '저녁 식사',
      memo: '집에서 맛있는 저녁을 먹었다',
    ),
    // 15일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 15)),
      emotion: '기쁨',
      emotionAnimation: 'assets/animations/Great.json',
      spendingAmount: 45000,
      spendingDescription: '쇼핑',
      memo: '새 옷을 샀다',
    ),
    // 18일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 18)),
      emotion: '슬픔',
      emotionAnimation: 'assets/animations/UU.json',
      spendingAmount: 8000,
      spendingDescription: '교통비',
      memo: '비가 와서 우산을 샀다',
    ),
    // 20일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 20)),
      emotion: '평온',
      emotionAnimation: 'assets/animations/Done.json',
      spendingAmount: 22000,
      spendingDescription: '도서관',
      memo: '책을 읽었다',
    ),
    // 25일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 25)),
      emotion: '화남',
      emotionAnimation: 'assets/animations/Verify.json',
      spendingAmount: 15000,
      spendingDescription: '점심',
      memo: '음식이 맛없었다',
    ),
    // 28일 전
    EmotionSpendingDiary(
      date: DateTime.now().subtract(const Duration(days: 28)),
      emotion: '기쁨',
      emotionAnimation: 'assets/animations/Great.json',
      spendingAmount: 35000,
      spendingDescription: '영화',
      memo: '재미있는 영화를 봤다',
    ),
  ];

  List<EmotionSpendingDiary> get diaryEntries => _diaryEntries;

  void addEmotionData(EmotionSpendingDiary data) {
    // 같은 날짜의 기존 데이터가 있으면 제거
    _diaryEntries.removeWhere((entry) {
      final entryNormalized = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final dataNormalized = DateTime(
        data.date.year,
        data.date.month,
        data.date.day,
      );
      return entryNormalized.isAtSameMomentAs(dataNormalized);
    });

    // 새로운 데이터 추가
    _diaryEntries.add(data);
    print(
      '감정 데이터 추가됨: ${data.emotion} - ${data.date} - 총 ${_diaryEntries.length}개',
    );
    notifyListeners();
  }

  Map<DateTime, EmotionSpendingDiary> get diaryEntriesMap {
    return Map.fromEntries(
      _diaryEntries.map((entry) => MapEntry(entry.date, entry)),
    );
  }
}
