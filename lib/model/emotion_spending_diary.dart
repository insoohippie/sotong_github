import 'package:cloud_firestore/cloud_firestore.dart';

class EmotionSpendingDiary {
  final DateTime date;
  final String emotion;
  final String emotionAnimation;
  final double spendingAmount;
  final String spendingDescription;
  final String memo;

  EmotionSpendingDiary({
    required this.date,
    required this.emotion,
    required this.emotionAnimation,
    required this.spendingAmount,
    required this.spendingDescription,
    required this.memo,
  });

  factory EmotionSpendingDiary.fromMap(Map<String, dynamic> map) {
    return EmotionSpendingDiary(
      date: (map['date'] as Timestamp).toDate(),
      emotion: map['emotion'] ?? '',
      emotionAnimation: map['emotionAnimation'] ?? '',
      spendingAmount: (map['spendingAmount'] as num?)?.toDouble() ?? 0,
      spendingDescription: map['spendingDescription'] ?? '',
      memo: map['memo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'emotion': emotion,
    'emotionAnimation': emotionAnimation,
    'spendingAmount': spendingAmount,
    'spendingDescription': spendingDescription,
    'memo': memo,
  };
}
